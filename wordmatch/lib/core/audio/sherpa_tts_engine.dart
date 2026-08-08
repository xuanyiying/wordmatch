import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

/// 离线英文 TTS 引擎（基于 sherpa_onnx + Piper VITS）。
///
/// 解决国产 ROM（小米/华为等）系统 TTS 缺英文语音包导致 `flutter_tts` 静音的问题：
/// Piper VITS 模型直接内置在 APK assets 中，首次启动时从 assets 复制到应用目录，
/// 之后完全离线运行，**无需联网、无需用户任何系统设置**。
///
/// 模型：`vits-piper-en_US-lessac-medium`（男声，~64MB onnx + espeak-ng-data）。
/// 模型更新时调高 [_kModelVersion] 即可触发重新解压。
///
/// 使用：
/// ```dart
/// if (await SherpaTtsEngine.instance.ensureReady()) {
///   await SherpaTtsEngine.instance.speak('hello');
/// }
/// ```
class SherpaTtsEngine {
  SherpaTtsEngine._();
  static final SherpaTtsEngine instance = SherpaTtsEngine._();

  // ---- 模型资产位置 ----
  static const String _assetRoot =
      'assets/tts/vits-piper-en_US-lessac-medium';
  static const String _modelDirName = 'vits-piper-en_US-lessac-medium';
  static const String _modelFileName = 'en_US-lessac-medium.onnx';
  static const String _tokensFileName = 'tokens.txt';
  static const String _espeakDirName = 'espeak-ng-data';
  static const String _manifestName = '_manifest.txt';

  /// 模型版本号：assets 中的模型更新后递增此值，启动时会自动重新解压。
  /// v2: 强制重新解压，清除早期测试中可能残留的不完整模型文件。
  static const String _kModelVersion = '2';

  /// 模型总字节数估算值（onnx ~63MB + espeak-ng-data ~1.5MB），用于进度条计算。
  /// 实际字节数可能略有偏差，进度条会 clamp 到 [0, 1]，不影响功能。
  static const int _kEstimatedTotalBytes = 64 * 1024 * 1024;

  /// 解压进度 0..1（0 表示未开始，1 表示完成）。UI 监听此值显示进度。
  final ValueNotifier<double> progress = ValueNotifier<double>(0);

  /// 引擎是否就绪（模型已解压 + 可合成）。
  final ValueNotifier<bool> ready = ValueNotifier<bool>(false);

  /// 人类可读状态文案（供 UI 提示），null 表示无提示。
  final ValueNotifier<String?> status = ValueNotifier<String?>(null);

  sherpa_onnx.OfflineTts? _tts;
  AudioPlayer? _player;
  bool _bindingsInited = false;
  Future<bool>? _readyFuture;

  String? _modelRootPath;
  String? _lastWavPath;

  /// 模型根目录：`<supportDir>/sherpa-tts/vits-piper-en_US-lessac-medium`
  Future<String> _modelRoot() async {
    if (_modelRootPath != null) return _modelRootPath!;
    final support = await getApplicationSupportDirectory();
    return _modelRootPath = p.join(support.path, 'sherpa-tts', _modelDirName);
  }

  /// 临时 wav 路径：`<supportDir>/sherpa-tts/_last.wav`
  Future<String> _wavPath() async {
    if (_lastWavPath != null) return _lastWavPath!;
    final support = await getApplicationSupportDirectory();
    return _lastWavPath = p.join(support.path, 'sherpa-tts', '_last.wav');
  }

  /// 确保引擎就绪。模型已解压则立即返回 true；否则触发后台解压。
  /// 多次调用会复用同一个进行中的 Future，不会重复解压。
  Future<bool> ensureReady() async {
    if (ready.value) return true;
    if (_readyFuture != null) return _readyFuture!;
    _readyFuture = _doEnsure().whenComplete(() => _readyFuture = null);
    return _readyFuture!;
  }

  Future<bool> _doEnsure() async {
    try {
      final root = await _modelRoot();
      if (_isModelPresent(root) && _isVersionMatch(root)) {
        ready.value = true;
        progress.value = 1;
        status.value = null;
        debugPrint('[SherpaTts] model already present at $root');
        return true;
      }
      final ok = await _extractFromAssets(root);
      if (ok && _isModelPresent(root)) {
        await _writeVersion(root);
        ready.value = true;
        progress.value = 1;
        status.value = null;
        debugPrint('[SherpaTts] model extracted to $root');
        return true;
      }
      // _extractFromAssets 可能已设置更具体的错误文案（如"解压失败：xxx"），
      // 只在它没有设置时才用通用文案
      if (status.value == null || !status.value!.contains('失败')) {
        status.value = '语音引擎准备失败，将使用系统 TTS';
      }
      return false;
    } catch (e, st) {
      debugPrint('[SherpaTts] ensureReady error: $e\n$st');
      status.value = '语音引擎准备失败：$e';
      return false;
    }
  }

  /// 检查模型关键文件是否齐全（onnx + tokens + espeak-ng-data/phondata）。
  bool _isModelPresent(String root) {
    final onnx = File(p.join(root, _modelFileName));
    final tokens = File(p.join(root, _tokensFileName));
    final phondata = File(p.join(root, _espeakDirName, 'phondata'));
    return onnx.existsSync() &&
        tokens.existsSync() &&
        phondata.existsSync();
  }

  /// 版本文件路径：`<root>/.version`
  String _versionPath(String root) => p.join(root, '.version');

  bool _isVersionMatch(String root) {
    try {
      return File(_versionPath(root)).readAsStringSync().trim() == _kModelVersion;
    } catch (_) {
      return false;
    }
  }

  Future<void> _writeVersion(String root) async {
    try {
      await File(_versionPath(root)).writeAsString(_kModelVersion);
    } catch (_) {}
  }

  /// 从 APK assets 读取 manifest，逐文件复制到 [root]。
  ///
  /// assets 中的文件无法被 native FFI 直接按路径访问，必须先复制到真实文件系统。
  ///
  /// **逐文件处理**：每个文件加载后立即写入并释放，避免旧实现将全部 142 个文件
  /// （~65MB）同时缓存在内存中导致低内存设备 OOM 或被系统杀进程。
  Future<bool> _extractFromAssets(String root) async {
    status.value = '正在准备离线语音引擎（仅需一次）…';
    progress.value = 0;

    // 1. 读取 manifest（每行一个相对路径）
    final manifestStr =
        await rootBundle.loadString('$_assetRoot/$_manifestName');
    final files = manifestStr
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (files.isEmpty) {
      debugPrint('[SherpaTts] empty manifest');
      status.value = '语音引擎文件清单为空';
      return false;
    }

    debugPrint('[SherpaTts] extracting ${files.length} files to $root');

    // 2. 清理旧的半成品目录
    final rootDir = Directory(root);
    if (rootDir.existsSync()) {
      await rootDir.delete(recursive: true);
    }
    await rootDir.create(recursive: true);

    // 3. 逐文件：加载 → 分块写入 → 释放（峰值内存 = 单个最大文件 ~63MB）
    const chunkSize = 512 * 1024; // 512KB
    var written = 0;
    for (var i = 0; i < files.length; i++) {
      final relPath = files[i];
      try {
        final data = await rootBundle.load('$_assetRoot/$relPath');
        final dest = p.join(root, relPath);
        await File(dest).parent.create(recursive: true);

        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        final sink = File(dest).openWrite();
        try {
          for (var offset = 0; offset < bytes.length; offset += chunkSize) {
            final end = (offset + chunkSize).clamp(0, bytes.length);
            sink.add(bytes.sublist(offset, end));
            written += end - offset;
            progress.value = (written / _kEstimatedTotalBytes).clamp(0.0, 1.0);
          }
          await sink.flush();
        } finally {
          await sink.close();
        }
      } catch (e) {
        debugPrint('[SherpaTts] failed to extract $relPath: $e');
        status.value = '语音引擎解压失败：$relPath';
        return false;
      }
    }

    debugPrint('[SherpaTts] extracted ${files.length} files, '
        '${written / 1024 / 1024}MB');
    return _isModelPresent(root);
  }

  /// 合成并播放英文文本。未就绪或失败返回 false（调用方应回退 flutter_tts）。
  ///
  /// **关键**：如果引擎尚未就绪（首次启动正在解压），会**等待**解压完成而不是
  /// 立即返回 false。因为国产 ROM 上 flutter_tts 缺英文语音包会静音，立即回退
  /// 等于放弃发音。等待最多 20 秒（63MB 模型解压通常 3-8 秒）。
  ///
  /// **长文本处理**：sherpa_onnx 的 generateWithConfig 是同步 CPU 密集调用（阻塞
  /// UI 线程）。对超过 [_maxSingleChar] 的长文本（AI 例句/对话/词串烧），按句子
  /// 切分后逐句合成播放，每句都很短（毫秒级），避免单次超长合成长时间阻塞 UI，
  /// 同时保证英文发音始终走 sherpa_onnx（不依赖可能缺英文语音包的 flutter_tts）。
  static const int _maxSingleChar = 300;

  Future<bool> speak(String text, {double speed = 1.0}) async {
    final t = text.trim();
    if (t.isEmpty) return false;

    if (!ready.value) {
      debugPrint('[SherpaTts] speak: engine not ready, waiting for extraction…');
      final ok = await ensureReady().timeout(
        const Duration(seconds: 20),
        onTimeout: () => false,
      );
      if (!ok || !ready.value) {
        debugPrint('[SherpaTts] speak: still not ready after wait, giving up');
        return false;
      }
    }

    // 长文本按句子分句合成，避免同步合成长时间阻塞 UI 线程
    if (t.length > _maxSingleChar) {
      final segments = splitSentences(t);
      if (segments.isNotEmpty) {
        var anyPlayed = false;
        for (final seg in segments) {
          if (await _speakSingle(seg, speed: speed)) anyPlayed = true;
        }
        return anyPlayed;
      }
    }

    return _speakSingle(t, speed: speed);
  }

  /// 合成并播放单段文本（每段应保持较短，合成在毫秒级）。
  Future<bool> _speakSingle(String text, {double speed = 1.0}) async {
    try {
      await _ensureTts();
      if (_tts == null) return false;

      final audio = _tts!.generateWithConfig(
        text: text,
        config: sherpa_onnx.OfflineTtsGenerationConfig(
          sid: 0,
          speed: speed,
          silenceScale: 0.2,
        ),
      );
      if (audio.samples.isEmpty || audio.sampleRate == 0) {
        debugPrint('[SherpaTts] empty samples for "$text"');
        return false;
      }

      final wav = await _wavPath();
      final ok = sherpa_onnx.writeWave(
        filename: wav,
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );
      if (!ok) {
        debugPrint('[SherpaTts] writeWave failed');
        return false;
      }

      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.play(DeviceFileSource(wav));
      return true;
    } catch (e, st) {
      debugPrint('[SherpaTts] speak error: $e\n$st');
      return false;
    }
  }

  /// 将长文本按句子切分为短段。
  ///
  /// 在句子结尾标点（. ! ? …）后断开，保留标点，过滤空段与纯空白段。
  /// 找不到句子边界时（无标点），按最长单段上限做硬切分，避免单段过长阻塞 UI。
  @visibleForTesting
  static List<String> splitSentences(String text) {
    // 匹配"句尾标点 + 空白"作为分句点（lookbehind 保留标点）
    final parts = text
        .split(RegExp(r'(?<=[.!?…])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    // 若整段无句尾标点，退化为按固定长度硬切分，保证每段不会过长
    if (parts.length == 1 && parts.first.length > _maxSingleChar) {
      return hardSplit(parts.first, _maxSingleChar);
    }
    return parts;
  }

  /// 按最大长度将长文本硬切分为多段（在单词边界处断开，避免切开单词）。
  @visibleForTesting
  static List<String> hardSplit(String text, int maxLen) {
    final result = <String>[];
    var remaining = text;
    while (remaining.length > maxLen) {
      var cut = remaining.lastIndexOf(' ', maxLen);
      if (cut <= 0) cut = maxLen;
      result.add(remaining.substring(0, cut).trim());
      remaining = remaining.substring(cut).trim();
    }
    if (remaining.isNotEmpty) result.add(remaining);
    return result;
  }

  /// 停止当前播放。
  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  Future<void> _ensureTts() async {
    if (_tts != null) return;
    if (!_bindingsInited) {
      sherpa_onnx.initBindings();
      _bindingsInited = true;
    }
    final root = await _modelRoot();
    final config = sherpa_onnx.OfflineTtsConfig(
      model: sherpa_onnx.OfflineTtsModelConfig(
        vits: sherpa_onnx.OfflineTtsVitsModelConfig(
          model: p.join(root, _modelFileName),
          lexicon: '',
          tokens: p.join(root, _tokensFileName),
          dataDir: p.join(root, _espeakDirName),
        ),
        numThreads: 2,
        debug: false,
        provider: 'cpu',
      ),
      maxNumSenetences: 1,
    );
    _tts = sherpa_onnx.OfflineTts(config);
    debugPrint('[SherpaTts] OfflineTts created');
  }

  /// 释放资源（App 退出时调用）。
  Future<void> dispose() async {
    try {
      _tts?.free();
    } catch (_) {}
    _tts = null;
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }
}
