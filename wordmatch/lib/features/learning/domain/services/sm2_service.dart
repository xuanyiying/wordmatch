// SM-2 间隔重复算法
// 基于用户的匹配耗时和错误次数计算质量评分 (Quality, 0-5)
// 并据此更新复习间隔和难度因子

/// 单词学习进度记录
class WordProgress {
  final String wordId;
  final String bookId;
  final double easinessFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReviewDate;
  final int lastQuality;
  final bool isMastered;
  final int reviewDebt;

  const WordProgress({
    required this.wordId,
    required this.bookId,
    this.easinessFactor = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    required this.nextReviewDate,
    this.lastQuality = 0,
    this.isMastered = false,
    this.reviewDebt = 0,
  });

  /// 从默认状态创建新进度
  factory WordProgress.newWord(String wordId, String bookId) {
    return WordProgress(
      wordId: wordId,
      bookId: bookId,
      nextReviewDate: DateTime.now(),
    );
  }

  WordProgress copyWith({
    double? easinessFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReviewDate,
    int? lastQuality,
    bool? isMastered,
    int? reviewDebt,
  }) =>
      WordProgress(
        wordId: wordId,
        bookId: bookId,
        easinessFactor: easinessFactor ?? this.easinessFactor,
        intervalDays: intervalDays ?? this.intervalDays,
        repetitions: repetitions ?? this.repetitions,
        nextReviewDate: nextReviewDate ?? this.nextReviewDate,
        lastQuality: lastQuality ?? this.lastQuality,
        isMastered: isMastered ?? this.isMastered,
        reviewDebt: reviewDebt ?? this.reviewDebt,
      );
}

/// SM-2 算法核心服务
class Sm2Service {
  Sm2Service._();

  /// 根据匹配耗时、错误次数和多维行为信号计算 Quality 评分
  ///
  /// 基础分：
  /// Q=5：秒配，无错误（熟练）
  /// Q=3：思考超过3秒，或错1次后配对（模糊）
  /// Q=1：错2次以上，或使用提示道具（陌生）
  ///
  /// 多维行为信号微调：
  /// 点发音 +0.5，查词根 -0.5，查AI助记 -1.0
  /// 最终 clamp 到 0-6 区间后四舍五入为 int
  static int calculateQuality({
    required int matchTimeMs,
    required int errorCount,
    bool usedHint = false,
    int soundTapCount = 0,
    int rootLensTapCount = 0,
    int aiMnemonicTapCount = 0,
  }) {
    double q;
    if (usedHint) {
      q = 1;
    } else if (errorCount >= 2) {
      q = 1;
    } else if (errorCount == 1) {
      q = 3;
    } else if (matchTimeMs > 3000) {
      q = 3;
    } else {
      q = 5;
    }

    if (soundTapCount >= 1) q += 0.5;
    if (rootLensTapCount >= 1) q -= 0.5;
    if (aiMnemonicTapCount >= 1) q -= 1.0;

    final clamped = q.clamp(0.0, 6.0);
    return clamped.round();
  }

  /// 更新单词进度（核心 SM-2 逻辑）
  ///
  /// 返回更新后的 WordProgress
  static WordProgress updateProgress(WordProgress current, int quality) {
    double ef = current.easinessFactor;
    int rep = current.repetitions;
    int interval = current.intervalDays;

    if (quality < 3) {
      // 评分低于3：重置
      rep = 0;
      interval = 1;
    } else {
      // 评分>=3：继续推进
      rep += 1;
      if (rep == 1) {
        interval = 1;
      } else if (rep == 2) {
        interval = 6;
      } else {
        interval = (interval * ef).round();
      }
    }

    // 更新难度因子
    ef = _updateEasinessFactor(ef, quality);

    // 计算下次复习日期
    final nextDate = DateTime.now().add(Duration(days: interval));

    // 判断是否已掌握（间隔>21天）
    final mastered = interval >= 21;

    return current.copyWith(
      easinessFactor: ef,
      intervalDays: interval,
      repetitions: rep,
      nextReviewDate: nextDate,
      lastQuality: quality,
      isMastered: mastered,
    );
  }

  /// 更新难度因子 (Easiness Factor)
  static double _updateEasinessFactor(double ef, int quality) {
    final newEf = ef + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
    return newEf < 1.3 ? 1.3 : newEf;
  }

  /// 批量获取今日需要复习的单词ID
  ///
  /// 加入复习债务上限机制：每日最多 [maxDailyReview] 词。
  /// 超出的部分由 [calculateDebt] 计入债务，并在后续天数优先消化
  /// （未选中的 overdue 词 nextReviewDate 仍为过去，次日会重新进入 overdue 池）。
  static List<String> getTodayReviewWords(
      List<WordProgress> allProgress, DateTime today,
      {int maxDailyReview = 200}) {
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // 找出所有需要今日复习的单词（nextReviewDate 在今天范围内）
    final dueWords = allProgress
        .where((p) =>
            !p.isMastered &&
            !p.nextReviewDate.isBefore(todayStart) &&
            p.nextReviewDate.isBefore(todayEnd))
        .toList();

    // 还要找出已经过期但还没复习的单词
    final overdueWords = allProgress
        .where((p) => !p.isMastered && p.nextReviewDate.isBefore(todayStart))
        .toList();

    final allDue = [...overdueWords, ...dueWords];

    if (allDue.length <= maxDailyReview) {
      // 不超限，全部推送
      return allDue.map((p) => p.wordId).toList();
    }

    // 超限：优先推送过期最久的（overdue 在前），剩余计入债务，
    // 其 nextReviewDate 保持过去，次日会再次进入 overdue 池被消化。
    final todayWords = allDue.take(maxDailyReview);
    return todayWords.map((p) => p.wordId).toList();
  }

  /// 计算今日实际被上限卡掉、无法完成的复习债务量
  ///
  /// 即"今日到期 + 已过期"总数中超出每日上限的部分。
  /// 与 [getTodayReviewWords] 保持口径一致，供 UI 展示债务减免提示。
  static int calculateDebt(List<WordProgress> allProgress, DateTime today,
      {int maxDailyReview = 200}) {
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final overdueCount = allProgress
        .where((p) => !p.isMastered && p.nextReviewDate.isBefore(todayStart))
        .length;
    final dueTodayCount = allProgress
        .where((p) =>
            !p.isMastered &&
            !p.nextReviewDate.isBefore(todayStart) &&
            p.nextReviewDate.isBefore(todayEnd))
        .length;
    final totalDue = overdueCount + dueTodayCount;
    if (totalDue <= maxDailyReview) return 0;
    return totalDue - maxDailyReview;
  }

  /// 计算债务减免提示文案
  static String getDebtReliefMessage(int debtCount) {
    if (debtCount <= 0) return '';
    return '今日已为你减免 $debtCount 个复习词，别有压力，慢慢来~';
  }

  /// 计算每日新词量（考虑债务）
  static int calculateDailyNewWords({
    required int totalWords,
    required int masteredWords,
    required int remainingDays,
    required int availableMinutes,
    int currentDebt = 0,
  }) {
    if (remainingDays <= 0) return 0;

    // 基础公式
    final base = ((totalWords - masteredWords) / remainingDays * 1.2).round();

    // 时长约束：1分钟处理1.5个新词
    final timeLimit = (availableMinutes / 1.5 * 0.7).round(); // 70%时间给新词

    final result = base < timeLimit ? base : timeLimit;

    // 有债务时新词减半
    if (currentDebt > 0) {
      return (result / 2).round().clamp(0, result);
    }

    return result.clamp(0, 50); // 最多每天50个新词
  }
}
