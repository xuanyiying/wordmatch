import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordmatch/features/learning/data/models/wrong_word.dart';
import 'package:wordmatch/features/learning/domain/services/plan_service.dart';
import 'package:wordmatch/features/learning/domain/services/sm2_service.dart';

/// 本地进度存储（MVP 阶段使用 SharedPreferences）
/// Phase 1 后期迁移到 drift/SQLite
class ProgressStorage {
  static const _progressKey = 'word_progress';
  static const _planKey = 'learning_plan';
  static const _wrongWordsKey = 'wrong_words';
  static const _dailyTaskStateKey = 'daily_task_state';
  static const _streakKey = 'learning_streak';

  SharedPreferences? _prefs;

  /// 是否已初始化
  bool get isInitialized => _prefs != null;
  Map<String, WordProgress> _cache = {};
  Map<String, WrongWord> _wrongWordsCache = {};

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFromDisk();
  }

  /// 从磁盘加载
  Future<void> _loadFromDisk() async {
    final jsonStr = _prefs?.getString(_progressKey);
    if (jsonStr != null) {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      _cache = map.map((k, v) => MapEntry(
            k,
            _progressFromJson(v as Map<String, dynamic>),
          ));
    }

    // 加载错词数据
    final wrongJsonStr = _prefs?.getString(_wrongWordsKey);
    if (wrongJsonStr != null) {
      final map = json.decode(wrongJsonStr) as Map<String, dynamic>;
      _wrongWordsCache = map.map((k, v) => MapEntry(
            k,
            WrongWord.fromJson(v as Map<String, dynamic>),
          ));
    }
  }

  /// 保存到磁盘
  Future<void> _saveToDisk() async {
    final map = _cache.map((k, v) => MapEntry(k, _progressToJson(v)));
    await _prefs?.setString(_progressKey, json.encode(map));

    // 保存错词数据
    final wrongMap = _wrongWordsCache.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs?.setString(_wrongWordsKey, json.encode(wrongMap));
  }

  /// 获取单词进度
  WordProgress? getProgress(String wordId) => _cache[wordId];

  /// 获取所有进度
  List<WordProgress> getAllProgress() => _cache.values.toList();

  /// 更新单词进度
  Future<void> updateProgress(WordProgress progress) async {
    _cache[progress.wordId] = progress;
    await _saveToDisk();
    await _recordStreak();
  }

  /// 批量更新进度
  Future<void> updateAllProgress(List<WordProgress> progressList) async {
    for (final p in progressList) {
      _cache[p.wordId] = p;
    }
    await _saveToDisk();
    await _recordStreak();
  }

  /// 获取已掌握的单词数
  int getMasteredCount() => _cache.values.where((p) => p.isMastered).length;

  /// 获取已学习的单词数
  int getLearnedCount() => _cache.length;

  /// 保存学习计划设置
  Future<void> savePlanSettings({
    required String bookId,
    required DateTime examDate,
    required int dailyMinutes,
    int? dailyNewWords,
  }) async {
    await _prefs?.setString(
        _planKey,
        json.encode({
          'bookId': bookId,
          'examDate': examDate.toIso8601String(),
          'dailyMinutes': dailyMinutes,
          'dailyNewWords': dailyNewWords,
        }));
  }

  /// 读取学习计划设置
  Map<String, dynamic>? getPlanSettings() {
    final jsonStr = _prefs?.getString(_planKey);
    if (jsonStr == null) return null;
    return json.decode(jsonStr) as Map<String, dynamic>;
  }

  /// 是否是首次使用
  bool get isFirstTime => _cache.isEmpty && getPlanSettings() == null;

  // ==================== 每日任务状态 ====================

  /// 保存今日任务状态
  Future<void> saveDailyTaskState(DailyTaskState state) async {
    await _prefs?.setString(_dailyTaskStateKey, json.encode(state.toJson()));
  }

  /// 读取今日任务状态（跨天自动失效返回 null）
  DailyTaskState? getDailyTaskState() {
    final jsonStr = _prefs?.getString(_dailyTaskStateKey);
    if (jsonStr == null) return null;
    final state =
        DailyTaskState.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
    // 跨天自动失效
    final now = DateTime.now();
    final stateDate =
        DateTime(state.date.year, state.date.month, state.date.day);
    final todayDate = DateTime(now.year, now.month, now.day);
    if (stateDate != todayDate) return null;
    return state;
  }

  /// 清除今日任务状态（推进到下一个学习计划时调用）
  Future<void> clearDailyTaskState() async {
    await _prefs?.remove(_dailyTaskStateKey);
  }

  // ==================== 错词本功能 ====================

  /// 添加错词记录（已存在则累加错误次数）
  Future<void> addWrongWord({
    required String wordId,
    required String bookId,
    String context = '匹配失败',
  }) async {
    final existing = _wrongWordsCache[wordId];
    if (existing != null) {
      final updatedContexts = [...existing.wrongContexts, context];
      // 只保留最近 5 条上下文
      if (updatedContexts.length > 5) {
        updatedContexts.removeRange(0, updatedContexts.length - 5);
      }
      _wrongWordsCache[wordId] = existing.copyWith(
        wrongCount: existing.wrongCount + 1,
        lastWrongAt: DateTime.now(),
        wrongContexts: updatedContexts,
      );
    } else {
      _wrongWordsCache[wordId] = WrongWord(
        wordId: wordId,
        bookId: bookId,
        wrongCount: 1,
        lastWrongAt: DateTime.now(),
        wrongContexts: [context],
      );
    }
    await _saveToDisk();
  }

  /// 移除错词（通关重练后调用）
  Future<void> removeWrongWord(String wordId) async {
    _wrongWordsCache.remove(wordId);
    await _saveToDisk();
  }

  /// 批量移除错词
  Future<void> removeWrongWords(List<String> wordIds) async {
    for (final id in wordIds) {
      _wrongWordsCache.remove(id);
    }
    await _saveToDisk();
  }

  /// 清空所有错词
  Future<void> clearWrongWords() async {
    _wrongWordsCache.clear();
    await _saveToDisk();
  }

  /// 获取所有错词列表（按错误次数降序）
  List<WrongWord> getWrongWords() {
    final list = _wrongWordsCache.values.toList();
    list.sort((a, b) => b.wrongCount.compareTo(a.wrongCount));
    return list;
  }

  /// 获取指定词库的错词列表
  List<WrongWord> getWrongWordsByBook(String bookId) {
    return getWrongWords().where((w) => w.bookId == bookId).toList();
  }

  /// 获取错词总数
  int getWrongWordCount() => _wrongWordsCache.length;

  /// 获取指定错词
  WrongWord? getWrongWord(String wordId) => _wrongWordsCache[wordId];

  // ==================== 连续打卡（Streak） ====================

  /// 获取当前连续打卡天数
  ///
  /// 规则：若今天已学习，返回当前连续天数；
  /// 若今天未学但昨天学过，仍返回连续天数（鼓励今天继续）；
  /// 否则返回 0。
  int getStreakDays() {
    final jsonStr = _prefs?.getString(_streakKey);
    if (jsonStr == null) return 0;
    try {
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final lastDate = data['lastDate'] as String? ?? '';
      final count = data['count'] as int? ?? 0;
      final today = _dateStr(DateTime.now());
      if (lastDate == today) return count;
      final yesterday =
          _dateStr(DateTime.now().subtract(const Duration(days: 1)));
      if (lastDate == yesterday) return count;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// 记录一次学习活动（在 updateProgress 中自动调用）
  ///
  /// 今天首次学习：若昨天有记录则连续 +1，否则重置为 1。
  Future<void> _recordStreak() async {
    final today = _dateStr(DateTime.now());
    final jsonStr = _prefs?.getString(_streakKey);
    String lastDate = '';
    int count = 0;
    if (jsonStr != null) {
      try {
        final data = json.decode(jsonStr) as Map<String, dynamic>;
        lastDate = data['lastDate'] as String? ?? '';
        count = data['count'] as int? ?? 0;
      } catch (_) {
        // 损坏数据，重置
      }
    }
    if (lastDate == today) return; // 今天已记录
    final yesterday =
        _dateStr(DateTime.now().subtract(const Duration(days: 1)));
    final newCount = lastDate == yesterday ? count + 1 : 1;
    await _prefs?.setString(
        _streakKey, json.encode({'lastDate': today, 'count': newCount}));
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // 序列化辅助
  Map<String, dynamic> _progressToJson(WordProgress p) => {
        'wordId': p.wordId,
        'bookId': p.bookId,
        'easinessFactor': p.easinessFactor,
        'intervalDays': p.intervalDays,
        'repetitions': p.repetitions,
        'nextReviewDate': p.nextReviewDate.toIso8601String(),
        'lastQuality': p.lastQuality,
        'isMastered': p.isMastered,
        'reviewDebt': p.reviewDebt,
      };

  WordProgress _progressFromJson(Map<String, dynamic> json) => WordProgress(
        wordId: json['wordId'] as String,
        bookId: json['bookId'] as String,
        easinessFactor: (json['easinessFactor'] as num).toDouble(),
        intervalDays: json['intervalDays'] as int,
        repetitions: json['repetitions'] as int,
        nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
        lastQuality: json['lastQuality'] as int,
        isMastered: json['isMastered'] as bool,
        reviewDebt: json['reviewDebt'] as int? ?? 0,
      );
}
