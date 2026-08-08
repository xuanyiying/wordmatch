import 'package:wordmatch/core/subscription/subscription_service.dart';
import 'package:wordmatch/features/ai/data/prompts/ai_prompts.dart';
import 'package:wordmatch/features/ai/data/services/ai_client.dart';
import 'package:wordmatch/features/wordbook/data/services/custom_wordbook_importer.dart';

/// AI 清洗结果
class AiCleanResult {
  /// 清洗后的词条列表
  final List<AiCleanedWord> words;

  /// AI 处理耗时（毫秒）
  final int elapsedMs;

  /// 是否使用了 AI（false 表示降级到基础正则解析）
  final bool usedAi;

  /// 错误信息（null 表示成功）
  final String? error;

  const AiCleanResult({
    required this.words,
    this.elapsedMs = 0,
    this.usedAi = true,
    this.error,
  });

  bool get isSuccess => error == null;
}

/// AI 清洗后的单个词条
class AiCleanedWord {
  final String word;
  final String? phonetic;
  final List<String> definition;
  final String? example;

  const AiCleanedWord({
    required this.word,
    required this.definition,
    this.phonetic,
    this.example,
  });

  /// 转换为 ImportedWord（用于兼容现有导入流程）
  ImportedWord toImportedWord() => ImportedWord(
        word: word,
        phonetic: phonetic,
        definition: definition,
      );
}

/// AI 清洗状态
enum AiCleanStatus {
  idle,
  loading, // AI 正在处理
  success, // 清洗成功，等待用户确认
  fallback, // AI 超时/失败，降级到基础解析
  error, // 清洗失败
}

/// AI 词库清洗服务
///
/// 用户粘贴杂乱文本（如从 PDF 复制的带有页码、乱码的词汇表），
/// 系统调用大模型进行结构化信息提取：
/// 1. 自动分离"单词"与"释义"
/// 2. 剔除无关字符（页码、编号、乱码）
/// 3. 补全缺失的考纲释义
///
/// 降级方案：AI 超时（15秒）时，自动使用基础正则解析
class AiCleanService {
  AiCleanService._();

  /// 大模型 API 地址（可配置）
  static String get apiUrl => AiClient.apiUrl;

  static set apiUrl(String value) => AiClient.apiUrl = value;

  /// 大模型 API Key（需用户配置或内嵌）
  static String get apiKey => AiClient.apiKey;

  static set apiKey(String value) => AiClient.apiKey = value;

  /// 大模型名称
  static String get model => AiClient.model;

  static set model(String value) => AiClient.model = value;

  /// 超时时间（毫秒）
  static const int timeoutMs = 15000;

  /// AI 清洗：调用大模型提取结构化词条
  static Future<AiCleanResult> cleanWithAi(String rawText) async {
    if (apiKey.isEmpty) {
      // 无 API Key，直接降级到基础解析
      return _fallbackClean(rawText);
    }

    // 接入 AI 额度控制，防止清洗被无限调用刷 API 成本。
    // 商业化未启用或用户为 Pro 时无限额度；免费用户超限则降级到基础解析。
    final allowed = await SubscriptionService.consumeAiQuota();
    if (!allowed) {
      final fb = _fallbackClean(rawText);
      return AiCleanResult(
        words: fb.words,
        usedAi: false,
        error: '今日 AI 清洗额度已用完，已降级到基础解析',
      );
    }

    final startTime = DateTime.now();

    try {
      final truncated =
          rawText.length > 3000 ? rawText.substring(0, 3000) : rawText;

      final result = await AiClient.complete(
        system: '你是一个专业的英语词汇清洗助手。'
            '你的任务是从杂乱的文本中提取英语单词和中文释义，并以严格的JSON格式返回结果。',
        user: AiPrompts.wordbookCleanPrompt(truncated),
        timeoutMs: timeoutMs,
        maxTokens: 2000,
      );

      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

      if (result == null) {
        return AiCleanResult(
          words: [],
          elapsedMs: elapsedMs,
          usedAi: false,
          error: 'AI 返回内容无法解析，已自动降级',
        );
      }

      final cleanedWords = _parseAiResponse(result);

      if (cleanedWords.isEmpty) {
        return AiCleanResult(
          words: [],
          elapsedMs: elapsedMs,
          usedAi: false,
          error: 'AI 返回内容无法解析，已自动降级',
        );
      }

      return AiCleanResult(
        words: cleanedWords,
        elapsedMs: elapsedMs,
        usedAi: true,
      );
    } catch (e) {
      // 超时或其他错误，降级到基础解析
      final fallbackResult = _fallbackClean(rawText);
      return AiCleanResult(
        words: fallbackResult.words,
        elapsedMs: timeoutMs,
        usedAi: false,
        error: e.toString().contains('TimeoutException')
            ? 'AI 处理超时，已自动降级到基础解析'
            : 'AI 处理失败：$e，已自动降级到基础解析',
      );
    }
  }

  /// 解析 AI 返回的 JSON result
  static List<AiCleanedWord> _parseAiResponse(Map<String, dynamic> result) {
    final wordsList = result['words'] as List<dynamic>?;
    if (wordsList == null) return [];

    return wordsList
        .map((w) {
          final m = w as Map<String, dynamic>?;
          if (m == null) return null;
          final word = (m['word'] as String?)?.trim() ?? '';
          if (word.isEmpty) return null;

          final defs = m['definition'];
          List<String> defsList;
          if (defs is List) {
            defsList = defs
                .map((d) => d.toString().trim())
                .where((d) => d.isNotEmpty)
                .toList();
          } else if (defs is String) {
            defsList = defs
                .split(RegExp(r'[;,；，]'))
                .map((d) => d.trim())
                .where((d) => d.isNotEmpty)
                .toList();
          } else {
            defsList = [];
          }

          return AiCleanedWord(
            word: word,
            phonetic: (m['phonetic'] as String?)?.trim(),
            definition: defsList,
            example: (m['example'] as String?)?.trim(),
          );
        })
        .whereType<AiCleanedWord>()
        .toList();
  }

  /// 降级方案：基础正则解析
  ///
  /// 尝试从文本中提取"英文单词 - 中文释义"的模式
  static AiCleanResult _fallbackClean(String rawText) {
    final words = <AiCleanedWord>[];

    // 模式1：单词 + 中文释义（常见格式）
    // 例如：abandon 放弃；抛弃
    final lines = rawText.split(RegExp(r'\n'));
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // 尝试匹配：英文单词 后面跟着中文
      // 英文部分：字母开头，可包含空格和连字符
      // 中文部分：包含中文字符
      final engMatch = RegExp(r"^([a-zA-Z][a-zA-Z\s\-']([a-zA-Z'])?)\s+")
          .firstMatch(trimmed);
      if (engMatch != null) {
        final word = engMatch.group(1)?.trim() ?? '';
        final rest = trimmed.substring(engMatch.group(0)!.length);
        // 过滤掉非中文/释义字符（如音标符号）
        final defText = rest.replaceAll(RegExp(r'[\/\[\]\(\)\d\.]'), '').trim();
        if (word.isNotEmpty && defText.isNotEmpty && word.length >= 2) {
          // 检查释义是否包含中文字符
          final hasChinese = RegExp(r'[一-鿿]').hasMatch(defText);
          if (hasChinese) {
            final defsList = defText
                .split(RegExp(r'[;；,，]'))
                .map((d) => d.trim())
                .where((d) => d.isNotEmpty)
                .toList();
            words.add(AiCleanedWord(word: word, definition: defsList));
          }
        }
      }

      // 模式2：编号格式 1. abandon 放弃
      if (engMatch == null) {
        final numberedMatch =
            RegExp(r'^\d+[\.\)\s]+([a-zA-Z][a-zA-Z\s\-]([a-zA-Z])?)\s+')
                .firstMatch(trimmed);
        if (numberedMatch != null) {
          final word = numberedMatch.group(1)?.trim() ?? '';
          final rest = trimmed.substring(numberedMatch.group(0)!.length);
          final defText =
              rest.replaceAll(RegExp(r'[\/\[\]\(\)\d\.]'), '').trim();
          if (word.isNotEmpty && defText.isNotEmpty && word.length >= 2) {
            final hasChinese = RegExp(r'[一-鿿]').hasMatch(defText);
            if (hasChinese) {
              final defsList = defText
                  .split(RegExp(r'[;；,，]'))
                  .map((d) => d.trim())
                  .where((d) => d.isNotEmpty)
                  .toList();
              words.add(AiCleanedWord(word: word, definition: defsList));
            }
          }
        }
      }
    }

    // 去重
    final seen = <String>{};
    final deduped = words.where((w) {
      if (seen.contains(w.word.toLowerCase())) return false;
      seen.add(w.word.toLowerCase());
      return true;
    }).toList();

    return AiCleanResult(
      words: deduped,
      elapsedMs: 0,
      usedAi: false,
    );
  }

  /// 配置 API Key
  static void configure(String key, {String? url, String? modelName}) {
    apiKey = key;
    if (url != null) apiUrl = url;
    if (modelName != null) model = modelName;
  }

  /// 是否已配置 API Key
  static bool get isConfigured => apiKey.isNotEmpty;
}
