import 'dart:math';

class DailyLearningStat {
  final DateTime date;
  final int newWords;
  final int reviewWords;
  final int minutes;
  const DailyLearningStat({required this.date, required this.newWords, required this.reviewWords, required this.minutes});
  int get total => newWords + reviewWords;
}

class LearningStatsService {
  LearningStatsService._();

  static Future<List<DailyLearningStat>> fetchRecentDays(int days) async {
    final now = DateTime.now();
    final result = <DailyLearningStat>[];
    for (int i = days - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final seed = d.year * 10000 + d.month * 100 + d.day;
      final r = Random(seed);
      final learned = r.nextDouble() < 0.6;
      result.add(DailyLearningStat(
        date: d,
        newWords: learned ? r.nextInt(18) : 0,
        reviewWords: learned ? (8 + r.nextInt(40)) : 0,
        minutes: learned ? (3 + r.nextInt(45)) : 0,
      ));
    }
    return result;
  }

  static Future<(int totalWords, int streakDays, int totalMinutes)> fetchSummary() async {
    final list = await fetchRecentDays(365);
    int totalWords = 0;
    int totalMinutes = 0;
    int streak = 0;
    int cur = 0;
    for (final d in list) {
      totalWords += d.total;
      totalMinutes += d.minutes;
      if (d.total > 0) {
        cur++;
        if (cur > streak) streak = cur;
      } else {
        cur = 0;
      }
    }
    return (totalWords, streak, totalMinutes);
  }
}
