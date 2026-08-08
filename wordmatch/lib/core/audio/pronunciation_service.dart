import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wordmatch/core/audio/sherpa_tts_engine.dart';
import 'package:wordmatch/core/subscription/subscription_service.dart';
import 'package:wordmatch/core/subscription/subscription_tier.dart';

/// 发音引擎选择
enum PronunciationEngine {
  realHuman,
  offlineTts,
}

/// 统一的单词/句子发音服务（P2-5）
///
/// ## 核心策略
/// - **Pro 用户**：优先播放 `assets/audio/<word>.mp3` 真人音频；资源不存在时自动回退到系统 TTS
/// - **免费用户**：直接使用 `flutter_tts` 离线 TTS
///
/// ## 使用方法
/// ```dart
/// // 播单词（自动按订阅等级选择引擎）
/// await PronunciationService.speak('hello');
///
/// // 强制使用真人音频（会抛异常并回退 TTS）
/// await PronunciationService.speak('hello', forceEngine: PronunciationEngine.realHuman);
///
/// // 停止当前播放
/// await PronunciationService.stop();
/// ```
///
/// ## 资源命名规范
/// 真人音频放在 `assets/audio/` 下：
/// - 命名：`<单词小写>.mp3`，特殊字符（非 a-z0-9）替换为 `_`
/// - 示例：`hello` → `hello.mp3`，`ice-cream` → `ice_cream.mp3`，`don't` → `don_t.mp3`
/// - 推荐格式：MP3 单声道 64kbps 44.1kHz
///
/// 详见 `assets/audio/README.txt`
class PronunciationService {
  PronunciationService._();

  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _ttsInited = false;

  static Future<void> _ensureTts() async {
    if (_ttsInited) return;
    try {
      // setLanguage 返回值：1=可用，2/0/false=语言缺失（国产 ROM 常见）
      final langResult = await _flutterTts.setLanguage('en-US');
      debugPrint('TTS setLanguage(en-US) => $langResult');
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      try {
        await _flutterTts.awaitSpeakCompletion(false);
      } catch (_) {}
      try {
        await _flutterTts.setSharedInstance(true);
      } catch (_) {}
      _ttsInited = true;
    } catch (e) {
      debugPrint('TTS init warn: $e');
    }
  }

  /// 离线 TTS 播放链：优先 sherpa_onnx（不依赖系统 TTS，国产 ROM 也能出声），
  /// 未就绪或失败时回退 flutter_tts（系统 TTS，模拟器/有英文语音包的设备可用）。
  static Future<bool> _speakOffline(String text) async {
    if (await SherpaTtsEngine.instance.speak(text)) {
      return true;
    }
    try {
      await _ensureTts();
      await _flutterTts.stop();
      final r = await _flutterTts.speak(text);
      // 平台差异：iOS 返回 1=成功，Android 返回 true=成功
      final ok = r == true || r == 1;
      if (!ok) debugPrint('TTS(flutter_tts) 未受理: "$text" => $r');
      return ok;
    } catch (e) {
      debugPrint('TTS(flutter_tts) 播放失败: $e');
      return false;
    }
  }

  /// 去除 TTS 文本中不应朗读的格式标记。
  ///
  /// AI 生成的例句/对话会用 `***word***` 包裹目标词用于界面高亮，若不清除就
  /// 直接交给 TTS，Piper/espeak-ng 会把 `***` 当成词边界/强调断点，导致被包裹
  /// 的单词被重复朗读（"部分单词重复朗读"）。这里统一在朗读入口剥离标记，
  /// 无论来自哪个页面，TTS 只收到纯净文本。
  static String _sanitizeForTts(String text) {
    var t = text.trim();
    // 剥离 ***...***（可为空内容），以及残留的孤立星号
    t = t.replaceAll(RegExp(r'\*\*\*[^*]*\*\*\*'), '');
    t = t.replaceAll('*', '');
    // 清理多空格与多余标点，避免音素器产生异常断点
    t = t.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return t;
  }

  /// 播放一个单词/句子的发音：
  /// - Pro 用户：先查 `assets/audio/word.mp3`，有就播真人音频；没有回退到 TTS
  /// - 免费用户：直接播离线 TTS
  ///
  /// [forceEngine] 可强制指定使用某个引擎（用于调试或特殊场景）
  ///
  /// 返回 `true` 表示已尝试播放（不一定成功，取决于硬件/引擎），
  /// 返回 `false` 表示传入内容为空或底层全部失败。
  static Future<bool> speak(String word, {PronunciationEngine? forceEngine}) async {
    // 朗读前剥离 ***...*** 等界面高亮标记，防止被 TTS 当成词边界导致重复朗读
    final cleaned = _sanitizeForTts(word);
    final w = cleaned.toLowerCase();
    if (w.isEmpty) return false;

    PronunciationEngine engine;
    if (forceEngine != null) {
      engine = forceEngine;
    } else {
      final tier = await SubscriptionService.getTier();
      engine = tier.isPro ? PronunciationEngine.realHuman : PronunciationEngine.offlineTts;
    }

    if (engine == PronunciationEngine.realHuman) {
      try {
        final safeName = w.replaceAll(RegExp(r'[^a-z0-9]'), '_');
        final assetPath = 'audio/$safeName.mp3';
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource(assetPath));
        return true;
      } catch (e) {
        debugPrint('真人音频不存在 ($w): $e，回退 TTS');
        engine = PronunciationEngine.offlineTts;
      }
    }

    if (engine == PronunciationEngine.offlineTts) {
      return _speakOffline(cleaned);
    }
    return false;
  }

  /// 停止当前播放（真人音频 + sherpa 离线 TTS + 系统 TTS 都停）
  static Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    try {
      await SherpaTtsEngine.instance.stop();
    } catch (_) {}
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
