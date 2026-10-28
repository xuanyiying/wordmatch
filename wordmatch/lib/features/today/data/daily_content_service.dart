import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:wordmatch/features/today/domain/models/daily_word.dart';
import 'package:wordmatch/features/today/domain/models/daily_quote.dart';

/// 每日内容服务：按日期从本地语料库取"每日一词"和"每日一句"
///
/// 取词规则：dayOfYear % 语料长度，保证每天稳定展示同一内容，
/// 且不同日期会轮换。
class DailyContentService {
  DailyContentService._();

  static List<DailyWord>? _wordsCache;
  static List<DailyQuote>? _quotesCache;

  /// 获取指定日期（默认今天）的每日一词
  static Future<DailyWord> getWordOfDay([DateTime? date]) async {
    final list = await _loadWords();
    if (list.isEmpty) {
      return const DailyWord(
        word: 'learn',
        phonetic: '/lɜːn/',
        pos: 'v.',
        meaning: '学习',
        example: 'Live and learn.',
        exampleTrans: '活到老，学到老。',
        source: '每日一词',
      );
    }
    final d = date ?? DateTime.now();
    return list[_dayOfYear(d) % list.length];
  }

  /// 获取指定日期（默认今天）的每日一句
  static Future<DailyQuote> getQuoteOfDay([DateTime? date]) async {
    final list = await _loadQuotes();
    if (list.isEmpty) {
      return const DailyQuote(
        text: 'Learn from yesterday, live for today, hope for tomorrow.',
        trans: '向昨天学习，为今天而活，对明天抱有希望。',
        work: '每日一句',
        author: '爱因斯坦',
      );
    }
    final d = date ?? DateTime.now();
    return list[_dayOfYear(d) % list.length];
  }

  /// 随机取一个每日一词（用于「换一个」，可排除当前词）
  static Future<DailyWord> getRandomWord([DailyWord? excluding]) async {
    final list = await _loadWords();
    if (list.length <= 1) return getWordOfDay();
    final candidates = excluding == null
        ? list
        : list.where((w) => w.word != excluding.word).toList();
    if (candidates.isEmpty) return list.first;
    candidates.shuffle();
    return candidates.first;
  }

  static Future<List<DailyWord>> _loadWords() async {
    if (_wordsCache != null) return _wordsCache!;
    try {
      final str = await rootBundle.loadString('assets/data/daily_words.json');
      final list = json.decode(str) as List<dynamic>;
      _wordsCache = list
          .map((e) => DailyWord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // 资产缺失或格式错误会导致「今日」页没有内容，需要显式记录以便排查
      log('DailyContentService: 每日单词加载失败', error: e);
      _wordsCache = [];
    }
    return _wordsCache!;
  }

  static Future<List<DailyQuote>> _loadQuotes() async {
    if (_quotesCache != null) return _quotesCache!;
    try {
      final str = await rootBundle.loadString('assets/data/daily_quotes.json');
      final list = json.decode(str) as List<dynamic>;
      _quotesCache = list
          .map((e) => DailyQuote.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('DailyContentService: 每日金句加载失败', error: e);
      _quotesCache = [];
    }
    return _quotesCache!;
  }

  /// 一年中的第几天（0-based）
  static int _dayOfYear(DateTime d) {
    return d.difference(DateTime(d.year, 1, 1)).inDays;
  }
}
