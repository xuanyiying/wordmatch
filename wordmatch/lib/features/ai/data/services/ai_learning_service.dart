import 'dart:developer';

import 'package:wordmatch/core/subscription/subscription_service.dart';
import 'package:wordmatch/features/ai/data/prompts/ai_prompts.dart';
import 'package:wordmatch/features/ai/data/services/ai_client.dart';
import 'package:wordmatch/features/ai/data/services/ai_response_cache.dart';
import 'package:wordmatch/features/learning/data/services/mnemonic_service.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';
import 'package:wordmatch/features/wordbook/data/repositories/word_repository.dart';

/// AI 学习服务：助记、例句、同反义词网络
class AiLearningService {
  AiLearningService._();

  static final WordRepository _repo = WordRepository();

  /// 根据 wordId 获取纯英文单词文本
  ///
  /// 优先通过 WordRepository.findById 查词库（保证正确），
  /// 查不到时用正则兜底（自定义词库等边缘情况）。
  static Future<String> _resolveWord(String wordId) async {
    final w = await _repo.findById(wordId);
    if (w != null) return w.word;
    // 兜底：从 ID 后缀提取
    final match = RegExp(r'^(.+?)_(?:gaokao|cet4|cet6|it|kaoyan)$')
        .firstMatch(wordId);
    return match?.group(1) ?? wordId;
  }

  /// 根据 wordId 获取完整词条（含音标/例句/词根），用于本地兜底。
  ///
  /// 词库内置了美式音标、例句等真实数据，可优先用于离线兜底，
  /// 减少 AI 调用从而省成本。查不到返回 null。
  static Future<Word?> _resolveWordObject(String wordId) async {
    final w = await _repo.findById(wordId);
    if (w != null) return w;
    final match = RegExp(r'^(.+?)_(?:gaokao|cet4|cet6|it|kaoyan)$')
        .firstMatch(wordId);
    if (match == null) return null;
    return _repo.findByWordText(match.group(1)!);
  }

  // ==================== 实时助记 ====================

  /// 生成实时助记
  ///
  /// 优先读取缓存，未命中时调用 AI。未配置 API Key 或失败时返回 null。
  static Future<Mnemonic?> generateMnemonic(
    String wordId,
    List<String> definition,
  ) async {
    final allowed = await SubscriptionService.consumeAiQuota();
    if (!allowed) {
      return null;
    }
    final cached = await AiResponseCache.get('mnemonic', wordId);
    if (cached != null) {
      return _parseMnemonic(wordId, cached);
    }

    if (!AiClient.isConfigured) return null;

    try {
      final word = await _resolveWord(wordId);
      final result = await AiClient.complete(
        system: AiPrompts.systemMnemonicExpert,
        user: AiPrompts.mnemonicPrompt(word, definition),
        maxTokens: 500,
        useThinking: false,
      );
      if (result == null) return null;

      await AiResponseCache.set('mnemonic', wordId, result);
      return _parseMnemonic(wordId, result);
    } catch (e) {
      log('AiLearningService: 助记生成失败 (wordId=$wordId)', error: e);
      return null;
    }
  }

  static Mnemonic? _parseMnemonic(String wordId, Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final content = data['content'] as String?;
    if (type == null || content == null || content.isEmpty) return null;
    final validTypes = {'story', 'homophone', 'association'};
    if (!validTypes.contains(type)) return null;
    return Mnemonic(wordId: wordId, type: type, content: content);
  }

  // ==================== AI 例句 ====================

  /// 例句数据
  ///
  /// **AI 优先，本地仅作降级兜底**：AI 正常时用 AI 结果；仅当 AI 不可用
  /// （未配置 Key / 配额不足 / 请求失败）时，才回退到词库内置例句与音标。
  /// 调用 AI 时会把本地音标作为已知值传入 prompt，避免模型猜测失真。
  static Future<List<AiExampleSentence>> generateExampleSentences(
    String wordId,
    List<String> definition,
  ) async {
    final allowed = await SubscriptionService.consumeAiQuota();

    // AI 不可用（未配置 / 配额不足）：直接返回空，由 UI 提示「AI 未配置」。
    // 页面原本已展示词库内置例句（原有例句），此处不再用本地例句兜底，
    // 避免同一例句在「原有例句」与「AI 例句」两块中重复展示。
    if (!allowed || !AiClient.isConfigured) {
      return const [];
    }

    final cached = await AiResponseCache.get('examples', wordId);
    if (cached != null) {
      return _parseExampleSentences(cached);
    }

    try {
      final word = await _resolveWord(wordId);
      final localWord = await _resolveWordObject(wordId);
      final localPhonetic = localWord?.phoneticUs?.trim() ?? '';
      final result = await AiClient.complete(
        system: AiPrompts.systemJsonExpert,
        user: AiPrompts.exampleSentencesPrompt(
          word,
          definition,
          knownPhonetic: localPhonetic,
        ),
        maxTokens: 800,
        useThinking: false,
      );

      // AI 调用失败：返回空，由 UI 提示「AI 例句生成失败」，不重复展示本地例句
      if (result == null) {
        return const [];
      }

      // AI 返回缺少音标时，用本地真实音标补上
      if (localPhonetic.isNotEmpty) {
        final parsed = _parseExampleSentences(result);
        if (parsed.isEmpty) return const [];
        final first = parsed.first;
        if (first.phonetic.isEmpty) {
          result['phonetic'] = localPhonetic;
          return _parseExampleSentences(result);
        }
        return parsed;
      }

      await AiResponseCache.set('examples', wordId, result);
      return _parseExampleSentences(result);
    } catch (e) {
      // 异常：返回空，由 UI 提示，避免重复展示本地例句
      log('AiLearningService: 例句生成失败 (wordId=$wordId)', error: e);
      return const [];
    }
  }

  static List<AiExampleSentence> _parseExampleSentences(
    Map<String, dynamic> data,
  ) {
    final phonetic = (data['phonetic'] as String?)?.trim() ?? '';
    final sentences = data['sentences'] as List<dynamic>?;
    if (sentences == null) return [];

    return sentences
        .map((s) {
          final m = s as Map<String, dynamic>?;
          if (m == null) return null;
          final en = (m['en'] as String?)?.trim();
          final zh = (m['zh'] as String?)?.trim();
          if (en == null || en.isEmpty || zh == null || zh.isEmpty) {
            return null;
          }
          return AiExampleSentence(en: en, zh: zh, phonetic: phonetic);
        })
        .whereType<AiExampleSentence>()
        .toList();
  }

  // ==================== 同反义词网络 ====================

  /// 生成同义词/反义词网络
  static Future<WordNetworkResult> generateWordNetwork(
    String wordId,
    List<String> definition,
  ) async {
    final allowed = await SubscriptionService.consumeAiQuota();
    if (!allowed) {
      return const WordNetworkResult();
    }
    final cached = await AiResponseCache.get('network', wordId);
    if (cached != null) {
      return _parseWordNetwork(cached);
    }

    if (!AiClient.isConfigured) return const WordNetworkResult();

    try {
      final word = await _resolveWord(wordId);
      // 用词库真实词根拆解作为 related 线索，提升同源词准确性
      final localWord = await _resolveWordObject(wordId);
      final rootHint = localWord?.rootParts?.trim() ?? '';
      final result = await AiClient.complete(
        system: AiPrompts.systemJsonExpert,
        user: AiPrompts.wordNetworkPrompt(
          word,
          definition,
          rootHint: rootHint,
        ),
        maxTokens: 1000,
        useThinking: false,
      );
      if (result == null) return const WordNetworkResult();

      await AiResponseCache.set('network', wordId, result);
      return _parseWordNetwork(result);
    } catch (e) {
      log('AiLearningService: 同反义词网络生成失败 (wordId=$wordId)', error: e);
      return const WordNetworkResult();
    }
  }

  static WordNetworkResult _parseWordNetwork(Map<String, dynamic> data) {
    return WordNetworkResult(
      synonyms: _parseNetworkItems(data['synonyms']),
      antonyms: _parseNetworkItems(data['antonyms']),
      related: _parseNetworkItems(data['related']),
    );
  }

  static List<NetworkWord> _parseNetworkItems(dynamic list) {
    if (list is! List) return [];
    return list
        .map((item) {
          final m = item as Map<String, dynamic>?;
          if (m == null) return null;
          final word = (m['word'] as String?)?.trim();
          final definition = (m['definition'] as String?)?.trim();
          if (word == null || word.isEmpty) return null;
          return NetworkWord(
            word: word,
            definition: definition ?? '',
          );
        })
        .whereType<NetworkWord>()
        .toList();
  }

  // ==================== 口语对话练习 ====================

  /// 生成围绕目标单词的口语对话
  static Future<DialogueResult> generateDialogue(
    String wordId,
    List<String> definition,
  ) async {
    final allowed = await SubscriptionService.consumeAiQuota();
    if (!allowed) {
      return const DialogueResult();
    }
    final cached = await AiResponseCache.get('dialogue', wordId);
    if (cached != null) {
      return parseDialogue(cached);
    }

    if (!AiClient.isConfigured) return const DialogueResult();

    try {
      final word = await _resolveWord(wordId);
      final result = await AiClient.complete(
        system: AiPrompts.systemDialogueCoach,
        user: AiPrompts.dialoguePrompt(word, definition),
        maxTokens: 1000,
        useThinking: false,
      );
      if (result == null) return const DialogueResult();

      await AiResponseCache.set(
        'dialogue',
        wordId,
        result,
        ttl: const Duration(days: 30),
      );
      return parseDialogue(result);
    } catch (e) {
      log('AiLearningService: 口语对话生成失败 (wordId=$wordId)', error: e);
      return const DialogueResult();
    }
  }

  static DialogueResult parseDialogue(Map<String, dynamic> data) {
    final scenario = (data['scenario'] as String?)?.trim() ?? '';
    final phonetic = (data['phonetic'] as String?)?.trim() ?? '';
    final linesRaw = data['lines'] as List<dynamic>?;
    final lines = <DialogueLine>[];

    if (linesRaw != null) {
      for (final item in linesRaw) {
        final m = item as Map<String, dynamic>?;
        if (m == null) continue;
        final speaker = (m['speaker'] as String?)?.trim();
        final en = (m['en'] as String?)?.trim();
        final zh = (m['zh'] as String?)?.trim();
        if (speaker == null ||
            speaker.isEmpty ||
            en == null ||
            en.isEmpty ||
            zh == null ||
            zh.isEmpty) {
          continue;
        }
        lines.add(DialogueLine(speaker: speaker, en: en, zh: zh));
      }
    }

    return DialogueResult(scenario: scenario, phonetic: phonetic, lines: lines);
  }

  // ============ 词串烧：AI短文 ============

  /// 词串烧：用今日新词编成短文
  static Future<WordChainStory?> generateWordChainStory({
    required List<Word> todaysWords,
    required String bookName,
  }) async {
    final allowed = await SubscriptionService.consumeAiQuota();
    if (!allowed) {
      return null;
    }
    if (todaysWords.isEmpty) return null;

    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final sortedIds = [...todaysWords.map((w) => w.id)]..sort();
    final wordsHash = sortedIds.join(',').hashCode.toString();
    final cacheId = '${today}_$wordsHash';

    final cached = await AiResponseCache.get('word_chain', cacheId);
    if (cached != null) {
      return _parseWordChainStory(cached);
    }

    if (!AiClient.isConfigured) {
      return WordChainStory(
        title: 'Configure AI Key to Unlock',
        contentZh: '请在设置中配置 AI Key 后体验完整的词串烧功能，以下为示例占位内容。',
        segments: [
          StorySegment(text: 'This is a sample story. ', isTarget: false),
          ...todaysWords.take(3).expand((w) => [
                StorySegment(
                  text: w.word,
                  isTarget: true,
                  targetWordId: w.id,
                ),
                StorySegment(text: ', ', isTarget: false),
              ]),
          StorySegment(
              text:
                  ' appear in this placeholder. Configure your AI key in settings to get personalized stories with all ${todaysWords.length} words.',
              isTarget: false),
        ],
      );
    }

    try {
      final role = bookName.isEmpty ? '高考英语教研员' : '$bookName英语教研员';
      final wordsList = todaysWords
          .map((w) => '- ${w.word} (id: ${w.id})')
          .join('\n');
      final userPrompt = '''你是一位资深的$role。请用以下 ${todaysWords.length} 个目标单词编一篇 200-250 词的英语短文，难度对标高考/四级阅读理解。
要求：
1. 每个目标单词至少出现一次（可用词根变体），且必须真实出现在正文中；
2. 有完整情节（校园/科技/环保/人物故事等学生熟悉的场景），不要生硬堆词；
3. 标题有吸引力（英文，约5-10词）；
4. 中文导读约50字，概括故事内容；
5. 返回严格 JSON，格式：
   {
     "title": "...",
     "contentZh": "...",
     "segments": [
       { "type": "normal", "text": "普通文本..." },
       { "type": "target", "text": "abandon", "wordId": "abandon_gaokao" },
       ...按文章顺序把普通文本段和目标词交错排列
     ]
   }

segments 硬性要求：
- 每个 type 为 target 的段，text 必须是在正文中出现的目标词（使用其词根变体时也填该变体），wordId 必须逐字等于下方列表中该词的 wordId，禁止虚构、改写或写错
- 普通文本段用 type=normal 包裹，target 段按正文实际出现的顺序插入，保证最终能拼成完整文章
- 下方列表中有多少个目标词，正文就至少要有多少个 type=target 段（允许同一词出现多次）

目标单词列表（word + wordId，wordId 必须原样使用）：
$wordsList
''';

      final result = await AiClient.complete(
        system: AiPrompts.systemReadingTeacher,
        user: userPrompt,
        maxTokens: 1500,
      );
      if (result == null) return null;

      await AiResponseCache.set('word_chain', cacheId, result,
          ttl: const Duration(days: 7));
      return _parseWordChainStory(result);
    } catch (e) {
      log('AiLearningService: 词串故事生成失败 (cacheId=$cacheId)', error: e);
      return null;
    }
  }

  static WordChainStory? _parseWordChainStory(Map<String, dynamic> data) {
    final title = (data['title'] as String?)?.trim();
    final contentZh = (data['contentZh'] as String?)?.trim();
    final segmentsRaw = data['segments'] as List<dynamic>?;

    if (title == null ||
        title.isEmpty ||
        contentZh == null ||
        contentZh.isEmpty ||
        segmentsRaw == null) {
      return null;
    }

    final segments = <StorySegment>[];
    for (final item in segmentsRaw) {
      final m = item as Map<String, dynamic>?;
      if (m == null) continue;
      final type = (m['type'] as String?)?.trim();
      final text = (m['text'] as String?)?.trim() ?? '';
      if (text.isEmpty) continue;
      if (type == 'target') {
        final wordId = (m['wordId'] as String?)?.trim();
        segments.add(StorySegment(
          text: text,
          isTarget: true,
          targetWordId: wordId,
        ));
      } else {
        segments.add(StorySegment(text: text, isTarget: false));
      }
    }

    if (segments.isEmpty) return null;
    return WordChainStory(
      title: title,
      contentZh: contentZh,
      segments: segments,
    );
  }
}

/// AI 例句数据
class AiExampleSentence {
  final String en;
  final String zh;
  final String phonetic;

  const AiExampleSentence({
    required this.en,
    required this.zh,
    this.phonetic = '',
  });
}

/// 同反义词网络节点
class NetworkWord {
  final String word;
  final String definition;

  const NetworkWord({required this.word, required this.definition});
}

/// 同反义词网络结果
class WordNetworkResult {
  final List<NetworkWord> synonyms;
  final List<NetworkWord> antonyms;
  final List<NetworkWord> related;

  const WordNetworkResult({
    this.synonyms = const [],
    this.antonyms = const [],
    this.related = const [],
  });

  bool get isEmpty =>
      synonyms.isEmpty && antonyms.isEmpty && related.isEmpty;
}

/// 口语对话单条台词
class DialogueLine {
  final String speaker;
  final String en;
  final String zh;

  const DialogueLine({
    required this.speaker,
    required this.en,
    required this.zh,
  });
}

/// 口语对话练习结果
class DialogueResult {
  final String scenario;
  final String phonetic;
  final List<DialogueLine> lines;

  const DialogueResult({
    this.scenario = '',
    this.phonetic = '',
    this.lines = const [],
  });

  bool get isEmpty => scenario.isEmpty && lines.isEmpty;
}

// ============ 词串烧：AI短文 ============

/// 词串烧短文返回结构
class WordChainStory {
  final String title;
  final String contentZh;
  final List<StorySegment> segments;
  const WordChainStory({
    required this.title,
    required this.contentZh,
    required this.segments,
  });
}

/// 一段正文片段
class StorySegment {
  final String text;
  final bool isTarget;
  final String? targetWordId;
  const StorySegment({
    required this.text,
    required this.isTarget,
    this.targetWordId,
  });
}
