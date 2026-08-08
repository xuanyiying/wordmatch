import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:wordmatch/core/audio/pronunciation_service.dart';

/// TTS 播放结果
class SpeakResult {
  final bool success;
  final String? error;

  const SpeakResult({required this.success, this.error});

  factory SpeakResult.ok() => const SpeakResult(success: true);
  factory SpeakResult.fail(String error) =>
      SpeakResult(success: false, error: error);
}

/// 音频播放器工具
///
/// P2-5 起：`speakWord` / `speakSentence` 发音逻辑已委托给
/// [PronunciationService]，支持：
/// - Pro 用户：真人音频优先（`assets/audio/word.mp3`），不存在回退 TTS
/// - 免费用户：flutter_tts 离线 TTS
class AudioPlayerUtil {
  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;

  /// 预加载音效
  static Future<void> preload() async {
    if (_initialized) return;
    await _player.setReleaseMode(ReleaseMode.stop);
    _initialized = true;
  }

  /// 播放匹配成功音效
  static Future<void> playMatchSuccess() async {
    try {
      await _player.play(AssetSource('audio/match_success.mp3'));
    } catch (_) {}
  }

  /// 播放匹配失败音效
  static Future<void> playMatchFail() async {
    try {
      await _player.play(AssetSource('audio/match_fail.mp3'));
    } catch (_) {}
  }

  /// 播放 Combo 音效
  static Future<void> playCombo() async {
    try {
      await _player.play(AssetSource('audio/combo.mp3'));
    } catch (_) {}
  }

  /// 播放关卡完成音效
  static Future<void> playLevelComplete() async {
    try {
      await _player.play(AssetSource('audio/match_success.mp3'));
    } catch (_) {}
  }

  /// 播放英文文本发音（委托给 [PronunciationService]）
  ///
  /// P2-5 起：Pro 用户优先播放真人音频（`assets/audio/word.mp3`），
  /// 资源不存在时自动回退 flutter_tts；免费用户直接使用离线 TTS。
  static Future<SpeakResult> speakWord(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return SpeakResult.fail('文本为空');
    }
    try {
      final ok = await PronunciationService.speak(trimmed);
      if (ok) {
        return SpeakResult.ok();
      }
      return SpeakResult.fail('发音服务未播放（可能在模拟器上运行）');
    } catch (e) {
      debugPrint('AudioPlayerUtil: speak failed: $e');
      return SpeakResult.fail('语音播放失败：$e');
    }
  }

  /// 播放句子发音（委托给 [PronunciationService]，句子专用语义别名）
  static Future<SpeakResult> speakSentence(String text) async {
    return speakWord(text);
  }

  /// 停止当前播放（委托给 [PronunciationService]，同时停止真人音频与 TTS）
  static Future<void> stopSpeak() async {
    await PronunciationService.stop();
  }

  /// 释放资源
  static Future<void> dispose() async {
    await _player.dispose();
    await PronunciationService.stop();
    _initialized = false;
  }
}
