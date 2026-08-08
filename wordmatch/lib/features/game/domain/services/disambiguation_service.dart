import 'package:wordmatch/features/ai/data/prompts/ai_prompts.dart';
import 'package:wordmatch/features/ai/data/services/ai_client.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';

/// 消歧结果
class DisambiguationResult {
  /// 正确的单词
  final String correctWord;

  /// 正确的释义
  final String correctDefinition;

  /// 消歧提示文案
  final String message;

  const DisambiguationResult({
    required this.correctWord,
    required this.correctDefinition,
    required this.message,
  });
}

/// 错因消歧服务
/// 匹配失败时，生成消歧文案帮助用户理解错误原因
class DisambiguationService {
  DisambiguationService._();

  /// 生成消歧结果（本地规则引擎）
  ///
  /// [clickedWordText] 用户点击的卡牌文本
  /// [clickedDefinition] 用户点击的释义（如果是中文卡牌）
  /// [correctWord] 正确匹配的单词对象
  static DisambiguationResult? generateDisambiguation({
    required String clickedWordText,
    String? clickedDefinition,
    required Word correctWord,
  }) {
    final correctDef = correctWord.definition.join('；');
    final buffer = StringBuffer();

    // 情况1：用户选了错误的释义（点了一个中文但不是正确匹配的）
    if (clickedDefinition != null && clickedDefinition != correctDef) {
      buffer.write('正确答案是「$correctDef」');
      if (correctWord.definition.length > 1) {
        buffer.write('。${correctWord.word} 有多个释义：');
        for (var i = 0; i < correctWord.definition.length; i++) {
          buffer.write('${i + 1}. ${correctWord.definition[i]} ');
        }
      }
    }
    // 情况2：用户选了错误的英文单词
    else {
      buffer.write('「${correctWord.word}」的正确匹配是「$correctDef」');
      if (clickedWordText != correctWord.word) {
        buffer.write('，而不是「$clickedWordText」');
      }
    }

    if (buffer.isEmpty) return null;

    return DisambiguationResult(
      correctWord: correctWord.word,
      correctDefinition: correctDef,
      message: buffer.toString(),
    );
  }

  /// 生成简短消歧提示（用于底部浮层）
  static String generateShortHint({
    required String correctWord,
    required String correctDefinition,
  }) {
    return '💡 $correctWord = $correctDefinition';
  }

  /// AI 大模型消歧接口
  ///
  /// 使用大模型生成更智能、更有针对性的消歧文案，例如：
  /// "book 作动词才是预订（book a ticket），本关考查名词词义“书”哦。"
  ///
  /// [correctWord] 正确匹配的单词对象；[userSelection] 用户点错的卡牌文本
  /// （可能是英文单词，也可能是错误释义）。
  ///
  /// 内部先走本地规则引擎 [generateDisambiguation] 作为兜底；仅当 AI 已配置
  /// 时才调用大模型，任一环节失败（未配置 / 超时 / 解析失败）都会回退到本地
  /// 结果，保证游戏流程不受 AI 可用性影响。
  static Future<DisambiguationResult?> generateAIDisambiguation({
    required Word correctWord,
    required String userSelection,
    String? clickedDefinition,
  }) async {
    final local = generateDisambiguation(
      clickedWordText: userSelection,
      clickedDefinition: clickedDefinition,
      correctWord: correctWord,
    );

    // 未配置 API Key 时直接走本地兜底
    if (!AiClient.isConfigured) return local;

    try {
      final result = await AiClient.complete(
        system: AiPrompts.systemDisambiguationCoach,
        user: AiPrompts.disambiguationPrompt(
          correctWord: correctWord.word,
          correctDefinition: correctWord.definition.join('；'),
          userSelection: userSelection,
        ),
        temperature: 0.3,
        maxTokens: 300,
        timeoutMs: 6000,
      );

      final message = result?['message'] as String?;
      if (message == null || message.trim().isEmpty) return local;

      return DisambiguationResult(
        correctWord: correctWord.word,
        correctDefinition: correctWord.definition.join('；'),
        message: message.trim(),
      );
    } catch (_) {
      // AI 调用失败（网络/超时/解析）时回退本地规则，保证不影响游戏
      return local;
    }
  }
}
