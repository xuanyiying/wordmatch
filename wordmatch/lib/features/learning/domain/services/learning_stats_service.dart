import 'package:wordmatch/features/learning/data/repositories/progress_storage.dart';

/// 每日学习统计项
class DailyLearningStat {
  final DateTime date;
  final int newWords;
  final int reviewWords;
  final int minutes;
  const DailyLearningStat({
    required this.date,
    required this.newWords,
    required this.reviewWords,
    required this.minutes,
  });
  int get total => newWords + reviewWords;

  /// 从持久化的每日历史记录构建
  factory DailyLearningStat.fromHistory(DailyLearningHistory h) =>
      DailyLearningStat(
        date: h.date,
        newWords: h.newWords,
        reviewWords: h.reviewWords,
        minutes: h.minutes,
      );
}

/// 学习统计汇总
class LearningSummary {
  final int totalWords;
  final int streakDays;
  final int totalMinutes;
  const LearningSummary({
    required this.totalWords,
    required this.streakDays,
    required this.totalMinutes,
  });
}

/// 学习统计服务：基于 [ProgressStorage] 的真实学习记录生成统计。
class LearningStatsService {
  LearningStatsService._();

  /// 获取最近 [days] 天的每日学习统计（从早到晚）。
  static Future<List<DailyLearningStat>> fetchRecentDays(
    ProgressStorage storage,
    int days,
  ) async {
    if (!storage.isInitialized) await storage.init();
    return storage
        .getDailyHistory(days)
        .map(DailyLearningStat.fromHistory)
        .toList();
  }

  /// 获取累计统计：累计消灭词数、连续坚持天数、累计分钟数。
  static Future<LearningSummary> fetchSummary(ProgressStorage storage) async {
    if (!storage.isInitialized) await storage.init();

    final history = storage.getAllDailyHistory();

    // 累计消灭词数（新词 + 复习）
    int totalWords = 0;
    int totalMinutes = 0;
    for (final h in history) {
      totalWords += h.total;
      totalMinutes += h.minutes;
    }

    // 连续坚持天数（使用真实 streak 记录）
    final streakDays = storage.getStreakDays();

    return LearningSummary(
      totalWords: totalWords,
      streakDays: streakDays,
      totalMinutes: totalMinutes,
    );
  }
}
