import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart' show rootBundle;

import 'package:wordmatch/core/subscription/subscription_service.dart';
import 'package:wordmatch/features/ai/data/services/ai_client.dart';
import 'package:wordmatch/features/feed/domain/services/word_lemmatizer.dart';

/// 查词结果
class WordLookup {
  final String word;

  /// 美式音标
  final String? phonetic;

  /// 中文释义（词性. 释义）
  final List<String> definitions;

  /// 英文例句（AI 查词时提供）
  final String? example;

  /// 本句语境义原文（不含「语境义：」前缀，用于写回文章 gloss 缓存）
  final String? inContext;

  /// 来源：local（ECDICT 离线词典）/ ai
  final String origin;

  const WordLookup({
    required this.word,
    this.phonetic,
    required this.definitions,
    this.example,
    this.inContext,
    required this.origin,
  });
}

/// 查词服务：ECDICT 离线词典 → AI → null 三级
///
/// - 离线词典由 scripts/build_mini_ecdict.py 生成（约 3 万高频词条），
///   零成本零延迟零流量；assets 缺失时自动跳过本地层。
/// - AI 层返回语境义项 + 通用释义 + 音标（符合"AI 内容必须带音标"规范）。
class DictionaryService {
  DictionaryService._();

  static const String _assetPath = 'assets/dict/mini_ecdict.json';
  static const int _aiTimeoutMs = 15000;

  /// 词条：{"p": 音标, "pos": 词性, "d": 中文释义}
  static Map<String, Map<String, String>>? _entries;
  static bool _loadFailed = false;

  /// 懒加载离线词典（启动后首次查词时触发；公开供阅读页预加载后同步取义）
  static Future<void> ensureLoaded() async {
    if (_entries != null || _loadFailed) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final map = json.decode(raw) as Map<String, dynamic>;
      _entries = map.map((k, v) {
        final e = v as Map<String, dynamic>;
        return MapEntry(
          k,
          {
            'p': (e['p'] ?? '') as String,
            'pos': (e['pos'] ?? '') as String,
            'd': (e['d'] ?? '') as String,
          },
        );
      });
    } catch (_) {
      // assets 缺失（脚本未跑/未打包）：标记失败，后续直接走 AI
      _loadFailed = true;
      log('DictionaryService: 离线词典不可用，查词将走 AI');
    }
  }

  static bool get isLocalAvailable => _entries != null;

  /// 把 ECDICT 的 d 字段按中英文分号/逗号拆成义项列表（首条附词性）。
  /// ECDICT 义项按使用频率排序，首条即最常用义。
  static List<String> splitDefinitions(String pos, String d) {
    final parts = d
        .split(RegExp(r'[;；,，]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return const [];
    final hasPos = RegExp(r'^[a-z]+\.\s*').hasMatch(parts.first);
    final prefix = (!hasPos && pos.trim().isNotEmpty) ? '${pos.trim()} ' : '';
    return ['$prefix${parts.first}', ...parts.skip(1)];
  }

  /// 行内括注用的简短释义：词典最常用义（≤12 字）。
  /// 需先 [ensureLoaded]；无词条或无释义返回 null。
  /// 屈折形式（ran/tests/company's）直接查表失败时按词形还原兜底。
  static String? briefDefinition(String word) {
    final entry = _entries?[normalize(word)] ?? _lemmaEntry(word);
    if (entry == null) return null;
    final defs = splitDefinitions(entry['pos'] ?? '', entry['d'] ?? '');
    if (defs.isEmpty) return null;
    var brief = defs.first;
    if (brief.length > 12) brief = '${brief.substring(0, 12)}…';
    return brief;
  }

  /// 原形未命中时按还原候选逐个查表（单层，不做链式还原）。
  static Map<String, String>? _lemmaEntry(String word) {
    final entries = _entries;
    if (entries == null) return null;
    for (final c in WordLemmatizer.candidates(word)) {
      final entry = entries[normalize(c)];
      if (entry != null) return entry;
    }
    return null;
  }

  /// 规范化查询词：去首尾标点、转小写、折叠空白。
  /// 保留空格与连字符：长按短语（如 look forward to）不能被压成
  /// lookforwardto，否则离线词典与 AI 都无法正确识别。
  static String normalize(String word) {
    final collapsed =
        word.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    return collapsed
        .replaceAll(RegExp(r"[^a-z'\- ]"), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 查词：先离线词典，未收录再走 AI（AI 不可用时返回 null）。
  /// 阅读页长按弹卡是 AI 优先（见 word_lookup_sheet 的解析顺序）。
  static Future<WordLookup?> lookup(String word, {String? sentence}) async {
    final query = normalize(word);
    if (query.isEmpty) return null;
    return (await lookupLocal(query)) ??
        await lookupAi(query, sentence: sentence);
  }

  /// 仅查 ECDICT 离线词典（零网络）：精确匹配原形词条。
  static Future<WordLookup?> lookupLocal(String word) async {
    final query = normalize(word);
    if (query.isEmpty) return null;
    await ensureLoaded();
    final entry = _entries?[query];
    if (entry == null) return null;
    final defs = splitDefinitions(entry['pos'] ?? '', entry['d'] ?? '');
    if (defs.isEmpty) return null;
    return WordLookup(
      word: query,
      phonetic: (entry['p'] ?? '').isEmpty ? null : entry['p'],
      definitions: defs,
      origin: 'local',
    );
  }

  /// AI 查词（音标 + 语境义项 + 通用释义 + 例句）。
  /// 未配置 Key / 额度不足 / 超时或解析失败时返回 null。
  static Future<WordLookup?> lookupAi(String word,
      {String? sentence}) async {
    final query = normalize(word);
    if (query.isEmpty) return null;
    if (!AiClient.isConfigured) return null;
    final allowed = await SubscriptionService.consumeAiQuota();
    if (!allowed) return null;

    try {
      final result = await AiClient.complete(
        system: '你是权威英汉词典。结合给定的上下文句子查询单词/短语：'
            '必须给出美式音标（phonetic，JD 词典音标格式）、语境中适用的中文义项、'
            '以及最常见的 1-3 条通用释义。严格只输出 JSON，格式为'
            ' {"result": {"word": "", "phonetic": "", "in_context": "本句语境义", '
            '"definitions": ["词性. 中文释义"], "example": "一个简洁的英文例句"}}。',
        user: sentence == null || sentence.isEmpty
            ? '查词：$query'
            : '查词：$query\n上下文：${sentence.length > 120 ? sentence.substring(0, 120) : sentence}',
        timeoutMs: _aiTimeoutMs,
        maxTokens: 600,
      );
      if (result == null) return null;

      final defs = ((result['definitions'] as List?) ?? const [])
          .map((d) => d.toString().trim())
          .where((d) => d.isNotEmpty)
          .toList();
      final phonetic = (result['phonetic'] as String?)?.trim();
      final inContext = (result['in_context'] as String?)?.trim();
      // 语境义置顶展示
      if (inContext != null && inContext.isNotEmpty) {
        defs.insert(0, '语境义：$inContext');
      }
      if (defs.isEmpty) return null;
      return WordLookup(
        word: ((result['word'] as String?)?.trim().isNotEmpty ?? false)
            ? (result['word'] as String).trim()
            : query,
        phonetic: (phonetic == null || phonetic.isEmpty) ? null : phonetic,
        definitions: defs,
        example: (result['example'] as String?)?.trim(),
        inContext: (inContext == null || inContext.isEmpty) ? null : inContext,
        origin: 'ai',
      );
    } catch (e) {
      log('DictionaryService: AI 查词失败 $e');
      return null;
    }
  }
}
