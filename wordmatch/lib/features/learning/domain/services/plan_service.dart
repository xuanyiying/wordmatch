import 'package:wordmatch/features/learning/domain/services/sm2_service.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';

/// 学习计划
class LearningPlan {
  final String bookId;
  final DateTime examDate;
  final int dailyMinutes;
  final int dailyNewWords;
  final int dailyReviewWords;
  final int totalWords;
  final int masteredWords;
  final int remainingDays;
  final int reviewDebt;

  const LearningPlan({
    required this.bookId,
    required this.examDate,
    required this.dailyMinutes,
    required this.dailyNewWords,
    required this.dailyReviewWords,
    required this.totalWords,
    required this.masteredWords,
    required this.remainingDays,
    required this.reviewDebt,
  });

  LearningPlan copyWith({
    String? bookId,
    DateTime? examDate,
    int? dailyMinutes,
    int? dailyNewWords,
    int? dailyReviewWords,
    int? totalWords,
    int? masteredWords,
    int? remainingDays,
    int? reviewDebt,
  }) =>
      LearningPlan(
        bookId: bookId ?? this.bookId,
        examDate: examDate ?? this.examDate,
        dailyMinutes: dailyMinutes ?? this.dailyMinutes,
        dailyNewWords: dailyNewWords ?? this.dailyNewWords,
        dailyReviewWords: dailyReviewWords ?? this.dailyReviewWords,
        totalWords: totalWords ?? this.totalWords,
        masteredWords: masteredWords ?? this.masteredWords,
        remainingDays: remainingDays ?? this.remainingDays,
        reviewDebt: reviewDebt ?? this.reviewDebt,
      );
}

/// 每日任务持久化状态
class DailyTaskState {
  final String bookId;
  final DateTime date;
  final bool learningCompleted;
  final bool gameCompleted;
  final List<String> learnedWordIds;

  const DailyTaskState({
    required this.bookId,
    required this.date,
    this.learningCompleted = false,
    this.gameCompleted = false,
    this.learnedWordIds = const [],
  });

  bool get isAllCompleted => learningCompleted && gameCompleted;

  DailyTaskState copyWith({
    String? bookId,
    DateTime? date,
    bool? learningCompleted,
    bool? gameCompleted,
    List<String>? learnedWordIds,
  }) =>
      DailyTaskState(
        bookId: bookId ?? this.bookId,
        date: date ?? this.date,
        learningCompleted: learningCompleted ?? this.learningCompleted,
        gameCompleted: gameCompleted ?? this.gameCompleted,
        learnedWordIds: learnedWordIds ?? this.learnedWordIds,
      );

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'date': date.toIso8601String(),
        'learningCompleted': learningCompleted,
        'gameCompleted': gameCompleted,
        'learnedWordIds': learnedWordIds,
      };

  factory DailyTaskState.fromJson(Map<String, dynamic> json) => DailyTaskState(
        bookId: json['bookId'] as String,
        date: DateTime.parse(json['date'] as String),
        learningCompleted: json['learningCompleted'] as bool? ?? false,
        gameCompleted: json['gameCompleted'] as bool? ?? false,
        learnedWordIds: (json['learnedWordIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}

/// 今日任务
class DailyTask {
  final List<Word> newWords;
  final List<Word> reviewWords;
  final int newWordsTarget;
  final int reviewWordsTarget;
  final int completedNew;
  final int completedReview;
  final int wrongCount;
  final int score;
  final int maxCombo;

  /// 每日任务持久化状态
  final DailyTaskState? taskState;

  const DailyTask({
    this.newWords = const [],
    this.reviewWords = const [],
    this.newWordsTarget = 0,
    this.reviewWordsTarget = 0,
    this.completedNew = 0,
    this.completedReview = 0,
    this.wrongCount = 0,
    this.score = 0,
    this.maxCombo = 0,
    this.taskState,
  });

  bool get isCompleted =>
      completedNew >= newWordsTarget && completedReview >= reviewWordsTarget;

  /// 新词学习是否完成
  bool get hasLearnedToday => taskState?.learningCompleted ?? false;

  /// 消消乐是否完成
  bool get hasPlayedGameToday => taskState?.gameCompleted ?? false;

  /// 是否可以进入消消乐（学完新词即可）
  bool get canPlayGame => hasLearnedToday && !hasPlayedGameToday;

  /// 是否可以进入下一个学习计划
  bool get canAdvancePlan => hasLearnedToday && hasPlayedGameToday;

  /// 正确率：基于正确匹配数 vs 总尝试数（正确+错误）
  double get accuracy {
    final total = completedNew + completedReview + wrongCount;
    if (total == 0) return 0;
    return (completedNew + completedReview) / total;
  }

  DailyTask copyWith({
    List<Word>? newWords,
    List<Word>? reviewWords,
    int? newWordsTarget,
    int? reviewWordsTarget,
    int? completedNew,
    int? completedReview,
    int? wrongCount,
    int? score,
    int? maxCombo,
    DailyTaskState? taskState,
  }) =>
      DailyTask(
        newWords: newWords ?? this.newWords,
        reviewWords: reviewWords ?? this.reviewWords,
        newWordsTarget: newWordsTarget ?? this.newWordsTarget,
        reviewWordsTarget: reviewWordsTarget ?? this.reviewWordsTarget,
        completedNew: completedNew ?? this.completedNew,
        completedReview: completedReview ?? this.completedReview,
        wrongCount: wrongCount ?? this.wrongCount,
        score: score ?? this.score,
        maxCombo: maxCombo ?? this.maxCombo,
        taskState: taskState ?? this.taskState,
      );
}

/// 学习计划引擎
class PlanService {
  PlanService._();

  /// 生成学习计划
  static LearningPlan generatePlan({
    required String bookId,
    required DateTime examDate,
    required int dailyMinutes,
    required int totalWords,
    required int masteredWords,
    required List<WordProgress> allProgress,
    int? dailyNewWordsOverride,
  }) {
    final today = DateTime.now();
    final remainingDays = examDate.difference(today).inDays;
    final debt = Sm2Service.calculateDebt(allProgress, today);
    final reviewWords =
        Sm2Service.getTodayReviewWords(allProgress, today).length;

    // 如果用户自定义了每日新词量，优先使用；否则自动计算
    final dailyNewWords = dailyNewWordsOverride ??
        Sm2Service.calculateDailyNewWords(
          totalWords: totalWords,
          masteredWords: masteredWords,
          remainingDays: remainingDays > 0 ? remainingDays : 30,
          availableMinutes: dailyMinutes,
          currentDebt: debt,
        );

    return LearningPlan(
      bookId: bookId,
      examDate: examDate,
      dailyMinutes: dailyMinutes,
      dailyNewWords: dailyNewWords,
      dailyReviewWords: reviewWords,
      totalWords: totalWords,
      masteredWords: masteredWords,
      remainingDays: remainingDays,
      reviewDebt: debt,
    );
  }

  /// 生成今日任务
  static DailyTask generateDailyTask({
    required LearningPlan plan,
    required List<Word> allWords,
    required List<WordProgress> allProgress,
    DailyTaskState? existingTaskState,
  }) {
    final today = DateTime.now();

    // 获取今日复习词
    final reviewWordIds = Sm2Service.getTodayReviewWords(allProgress, today);
    final reviewWords =
        allWords.where((w) => reviewWordIds.contains(w.id)).toList();

    // 今日新词：学习完成后保留已学词（供词串烧/摸鱼刷词/消消乐继续使用），
    // 直到用户推进到下一计划（_advanceToNextPlan 清除任务状态）后再生成下一批
    List<Word> newWords;
    if (existingTaskState?.learningCompleted == true) {
      final learnedIds = existingTaskState?.learnedWordIds ?? const <String>[];
      newWords = allWords.where((w) => learnedIds.contains(w.id)).toList();
    } else {
      // 获取今日新词（未学过的）
      final learnedIds = allProgress.map((p) => p.wordId).toList();
      final newWordPool = allWords
          .where((w) => !learnedIds.contains(w.id) && w.bookId == plan.bookId)
          .toList();
      newWordPool.shuffle();
      newWords = newWordPool.take(plan.dailyNewWords).toList();
    }

    return DailyTask(
      newWords: newWords,
      reviewWords: reviewWords,
      newWordsTarget: plan.dailyNewWords,
      reviewWordsTarget: plan.dailyReviewWords,
      taskState: existingTaskState,
    );
  }
}
