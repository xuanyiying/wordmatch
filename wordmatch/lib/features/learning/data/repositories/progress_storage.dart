import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordmatch/features/learning/data/models/wrong_word.dart';
import 'package:wordmatch/features/learning/domain/services/plan_service.dart';
import 'package:wordmatch/features/learning/domain/services/sm2_service.dart';

/// 本地进度存储（SharedPreferences + 内存缓存）
///
/// 设计要点：
/// - **同步读取**：`getProgress` / `getAllProgress` / `getWrongWords` 等为同步接口，
///   可直接在 `build()` 中调用，调用方无需改成异步。
/// - **写合并**：变更只把对应数据域标记为脏，并在一个很短的合并窗口内把多次变更
///   合并为一次落盘。此前每次 `updateProgress` 都会把「进度 + 错词 + 每日历史」
///   三份 JSON 全部重新序列化并写盘，一局消消乐会产生数十次全量写盘，是明确的
///   卡顿与耗电来源。
/// - **落盘粒度**：进度、错词、每日历史三个数据域各自独立落盘，互不牵连。
class ProgressStorage {
  static const _progressKey = 'word_progress';
  static const _planKey = 'learning_plan';
  static const _wrongWordsKey = 'wrong_words';
  static const _dailyTaskStateKey = 'daily_task_state';
  static const _streakKey = 'learning_streak';
  static const _dailyHistoryKey = 'daily_learning_history';

  /// 写盘合并窗口：窗口内的多次变更合并为一次落盘
  static const Duration _coalesceWindow = Duration(milliseconds: 50);

  /// 全局单例。进度数据在进程内是唯一的一份，避免多个实例各自持有一份缓存。
  static final ProgressStorage instance = ProgressStorage();

  SharedPreferences? _prefs;
  bool _initialized = false;
  Future<void>? _initFuture;

  /// 是否已初始化
  bool get isInitialized => _initialized;

  Map<String, WordProgress> _cache = {};
  Map<String, WrongWord> _wrongWordsCache = {};
  Map<String, DailyLearningHistory> _dailyHistoryCache = {};

  // ---- 脏标记：记录哪些数据域需要落盘 ----
  bool _progressDirty = false;
  bool _wrongWordsDirty = false;
  bool _dailyHistoryDirty = false;

  /// 合并窗口定时器：窗口内的多次变更收敛为一次落盘
  Timer? _writeTimer;

  /// 写盘队列：所有落盘串行执行，避免并发写同一个 key
  Future<void> _writeQueue = Future<void>.value();

  // ---- 连续打卡（内存态）----
  String _streakLastDate = '';
  int _streakCount = 0;
  bool _streakDirty = false;

  /// 初始化（幂等）。重复调用不会重复读盘，也不会丢弃内存中的变更。
  Future<void> init() {
    if (_initialized) return Future<void>.value();
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFromDisk();
    _initialized = true;
  }

  /// 从磁盘加载
  Future<void> _loadFromDisk() async {
    final prefs = _prefs;

    final jsonStr = prefs?.getString(_progressKey);
    if (jsonStr != null) {
      try {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        _cache = map.map((k, v) => MapEntry(
              k,
              _progressFromJson(v as Map<String, dynamic>),
            ));
      } catch (e) {
        // 进度数据损坏时保留空缓存，避免整个应用无法启动
        developer.log('ProgressStorage: 进度数据解析失败，已重置', error: e);
        _cache = {};
      }
    }

    // 加载错词数据
    final wrongJsonStr = prefs?.getString(_wrongWordsKey);
    if (wrongJsonStr != null) {
      try {
        final map = json.decode(wrongJsonStr) as Map<String, dynamic>;
        _wrongWordsCache = map.map((k, v) => MapEntry(
              k,
              WrongWord.fromJson(v as Map<String, dynamic>),
            ));
      } catch (e) {
        developer.log('ProgressStorage: 错词数据解析失败，已重置', error: e);
        _wrongWordsCache = {};
      }
    }

    // 加载每日学习历史
    final dailyJsonStr = prefs?.getString(_dailyHistoryKey);
    if (dailyJsonStr != null) {
      try {
        final map = json.decode(dailyJsonStr) as Map<String, dynamic>;
        _dailyHistoryCache = map.map((k, v) => MapEntry(
              k,
              DailyLearningHistory.fromJson(v as Map<String, dynamic>),
            ));
      } catch (e) {
        developer.log('ProgressStorage: 每日历史解析失败，已重置', error: e);
        _dailyHistoryCache = {};
      }
    }

    // 加载连续打卡
    final streakJsonStr = prefs?.getString(_streakKey);
    if (streakJsonStr != null) {
      try {
        final data = json.decode(streakJsonStr) as Map<String, dynamic>;
        _streakLastDate = data['lastDate'] as String? ?? '';
        _streakCount = data['count'] as int? ?? 0;
      } catch (e) {
        developer.log('ProgressStorage: 打卡数据解析失败，已重置', error: e);
        _streakLastDate = '';
        _streakCount = 0;
      }
    }
  }

  // ==================== 写盘 ====================

  /// 是否有待落盘的数据
  bool get _hasDirty =>
      _progressDirty ||
      _wrongWordsDirty ||
      _dailyHistoryDirty ||
      _streakDirty;

  /// 标记进度数据为脏
  void _markProgressDirty() => _progressDirty = true;

  /// 标记错词数据为脏
  void _markWrongWordsDirty() => _wrongWordsDirty = true;

  /// 标记每日历史为脏
  void _markDailyHistoryDirty() => _dailyHistoryDirty = true;

  /// 安排一次合并写盘（后台执行，不阻塞调用方）。
  ///
  /// 合并窗口内的多次安排只会触发一次实际落盘。落盘是异步的，调用方返回时数据
  /// 已在内存缓存中并被安排落盘，但不保证已经写入磁盘——需要强保证时调用 [flush]。
  void _scheduleWrite() {
    _writeTimer ??= Timer(_coalesceWindow, () {
      _writeTimer = null;
      _enqueueWrite();
    });
  }

  /// 把一次落盘追加到写盘队列尾部（串行执行，避免并发写同一个 key）
  void _enqueueWrite() {
    _writeQueue = _writeQueue.then((_) => _writeDirty());
  }

  /// 把脏数据域写盘。写盘失败时保留脏标记，等待下一次落盘重试。
  ///
  /// 返回是否全部写入成功。
  Future<bool> _writeDirty() async {
    final prefs = _prefs;
    if (prefs == null) return false;

    var ok = true;

    if (_progressDirty) {
      // 先清标记再写入：期间产生的新变更会重新置脏，由下一次落盘补写
      _progressDirty = false;
      try {
        final map = _cache.map((k, v) => MapEntry(k, _progressToJson(v)));
        await prefs.setString(_progressKey, json.encode(map));
      } catch (e) {
        _progressDirty = true;
        ok = false;
        developer.log('ProgressStorage: 进度写盘失败', error: e);
      }
    }

    if (_wrongWordsDirty) {
      _wrongWordsDirty = false;
      try {
        final map = _wrongWordsCache.map((k, v) => MapEntry(k, v.toJson()));
        await prefs.setString(_wrongWordsKey, json.encode(map));
      } catch (e) {
        _wrongWordsDirty = true;
        ok = false;
        developer.log('ProgressStorage: 错词写盘失败', error: e);
      }
    }

    if (_dailyHistoryDirty) {
      _dailyHistoryDirty = false;
      try {
        final map = _dailyHistoryCache.map((k, v) => MapEntry(k, v.toJson()));
        await prefs.setString(_dailyHistoryKey, json.encode(map));
      } catch (e) {
        _dailyHistoryDirty = true;
        ok = false;
        developer.log('ProgressStorage: 每日历史写盘失败', error: e);
      }
    }

    if (_streakDirty) {
      _streakDirty = false;
      try {
        await prefs.setString(
          _streakKey,
          json.encode({'lastDate': _streakLastDate, 'count': _streakCount}),
        );
      } catch (e) {
        _streakDirty = true;
        ok = false;
        developer.log('ProgressStorage: 打卡写盘失败', error: e);
      }
    }

    return ok;
  }

  /// 立即落盘所有待写数据（应用进入后台、关键节点时调用，确保内存态与磁盘一致）
  Future<void> flush() async {
    // 取消待触发的合并写盘，改为立即写
    _writeTimer?.cancel();
    _writeTimer = null;

    // 等待队列中已排队的写盘执行完；期间可能又有写盘入队，需要继续等待
    while (true) {
      final pending = _writeQueue;
      await pending;
      if (identical(pending, _writeQueue)) break;
    }

    // 写盘期间可能又产生了新变更，继续落盘直到干净
    while (_hasDirty) {
      final ok = await _writeDirty();
      // 写盘失败时不做死循环重试，错误已记录日志
      if (!ok) break;
    }
  }

  // ==================== 单词进度 ====================

  /// 获取单词进度
  WordProgress? getProgress(String wordId) => _cache[wordId];

  /// 获取所有进度
  List<WordProgress> getAllProgress() => _cache.values.toList();

  /// 更新单词进度
  ///
  /// 高频单条更新：只更新内存缓存并安排一次合并落盘，不阻塞调用方。
  Future<void> updateProgress(WordProgress progress) async {
    _cache[progress.wordId] = progress;
    _markProgressDirty();
    _recordStreak();
    _scheduleWrite();
  }

  /// 批量更新进度（整局游戏只触发一次写盘）
  ///
  /// 关键节点：返回时保证已落盘，避免进程被回收导致整局进度丢失。
  Future<void> updateAllProgress(List<WordProgress> progressList) async {
    for (final p in progressList) {
      _cache[p.wordId] = p;
    }
    _markProgressDirty();
    _recordStreak();
    _scheduleWrite();
    await flush();
  }

  /// 获取已掌握的单词数
  int getMasteredCount() => _cache.values.where((p) => p.isMastered).length;

  /// 获取已学习的单词数
  int getLearnedCount() => _cache.length;

  // ==================== 学习计划 ====================

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
    try {
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      developer.log('ProgressStorage: 学习计划解析失败', error: e);
      return null;
    }
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
    DailyTaskState state;
    try {
      state =
          DailyTaskState.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
    } catch (e) {
      developer.log('ProgressStorage: 今日任务状态解析失败', error: e);
      return null;
    }
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
    _markWrongWordsDirty();
    _scheduleWrite();
  }

  /// 移除错词（通关重练后调用）
  Future<void> removeWrongWord(String wordId) async {
    _wrongWordsCache.remove(wordId);
    _markWrongWordsDirty();
    _scheduleWrite();
    await flush();
  }

  /// 批量移除错词（整局重练只触发一次写盘）
  Future<void> removeWrongWords(List<String> wordIds) async {
    for (final id in wordIds) {
      _wrongWordsCache.remove(id);
    }
    _markWrongWordsDirty();
    _scheduleWrite();
    await flush();
  }

  /// 清空所有错词
  Future<void> clearWrongWords() async {
    _wrongWordsCache.clear();
    _markWrongWordsDirty();
    _scheduleWrite();
    await flush();
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
    final today = _dateStr(DateTime.now());
    if (_streakLastDate == today) return _streakCount;
    final yesterday =
        _dateStr(DateTime.now().subtract(const Duration(days: 1)));
    if (_streakLastDate == yesterday) return _streakCount;
    return 0;
  }

  /// 记录一次学习活动（内存态更新，随写盘合并落盘）
  ///
  /// 今天首次学习：若昨天有记录则连续 +1，否则重置为 1。
  void _recordStreak() {
    final today = _dateStr(DateTime.now());
    if (_streakLastDate == today) return; // 今天已记录

    final yesterday =
        _dateStr(DateTime.now().subtract(const Duration(days: 1)));
    final newCount = _streakLastDate == yesterday ? _streakCount + 1 : 1;
    _streakLastDate = today;
    _streakCount = newCount;
    _streakDirty = true;
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ==================== 每日学习历史 ====================

  /// 记录一次学习活动（新词/复习），累计到当天。
  ///
  /// [newWords] 本日新增已学新词数，[reviewWords] 本日完成复习数，
  /// [minutes] 本日累计学习分钟数（追加）。
  Future<void> recordDailyActivity({
    int newWords = 0,
    int reviewWords = 0,
    int minutes = 0,
  }) async {
    if (newWords == 0 && reviewWords == 0 && minutes == 0) return;
    final dateStr = _dateStr(DateTime.now());
    final today = DateTime.now();
    final existing = _dailyHistoryCache[dateStr];
    final updated = DailyLearningHistory(
      date: DateTime(today.year, today.month, today.day),
      newWords: (existing?.newWords ?? 0) + newWords,
      reviewWords: (existing?.reviewWords ?? 0) + reviewWords,
      minutes: (existing?.minutes ?? 0) + minutes,
    );
    _dailyHistoryCache[dateStr] = updated;
    _markDailyHistoryDirty();
    // 学习活动同时累计连续打卡
    _recordStreak();
    _scheduleWrite();
    await flush();
  }

  /// 按日期范围获取每日学习历史（含当天）。
  ///
  /// 返回最近 [days] 天的记录（从早到晚），无记录的天数返回空统计。
  List<DailyLearningHistory> getDailyHistory(int days) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final result = <DailyLearningHistory>[];
    for (int i = days - 1; i >= 0; i--) {
      final d = todayStart.subtract(Duration(days: i));
      final key = _dateStr(d);
      final record = _dailyHistoryCache[key];
      result.add(record ??
          DailyLearningHistory(
            date: d,
            newWords: 0,
            reviewWords: 0,
            minutes: 0,
          ));
    }
    return result;
  }

  /// 获取全部每日学习历史（按日期从早到晚）
  List<DailyLearningHistory> getAllDailyHistory() {
    final list = _dailyHistoryCache.values.toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

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

/// 每日学习历史记录
class DailyLearningHistory {
  final DateTime date;
  final int newWords;
  final int reviewWords;
  final int minutes;

  const DailyLearningHistory({
    required this.date,
    this.newWords = 0,
    this.reviewWords = 0,
    this.minutes = 0,
  });

  int get total => newWords + reviewWords;

  DailyLearningHistory copyWith({
    DateTime? date,
    int? newWords,
    int? reviewWords,
    int? minutes,
  }) =>
      DailyLearningHistory(
        date: date ?? this.date,
        newWords: newWords ?? this.newWords,
        reviewWords: reviewWords ?? this.reviewWords,
        minutes: minutes ?? this.minutes,
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'newWords': newWords,
        'reviewWords': reviewWords,
        'minutes': minutes,
      };

  factory DailyLearningHistory.fromJson(Map<String, dynamic> json) =>
      DailyLearningHistory(
        date: DateTime.parse(json['date'] as String),
        newWords: json['newWords'] as int? ?? 0,
        reviewWords: json['reviewWords'] as int? ?? 0,
        minutes: json['minutes'] as int? ?? 0,
      );
}
