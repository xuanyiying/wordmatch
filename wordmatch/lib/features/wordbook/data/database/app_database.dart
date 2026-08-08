import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// 词库表
class Words extends Table {
  /// 单词唯一ID
  TextColumn get id => text()();

  /// 单词文本
  TextColumn get word => text()();

  /// 美式音标
  TextColumn get phoneticUs => text().nullable()();

  /// 英式音标
  TextColumn get phoneticUk => text().nullable()();

  /// 释义（JSON 数组格式）
  TextColumn get definition => text()();

  /// 例句
  TextColumn get exampleSentence => text().nullable()();

  /// 词频等级 (1-5)
  IntColumn get frequency => integer().withDefault(const Constant(3))();

  /// 所属词书ID
  TextColumn get bookId => text()();

  /// 词根拆分
  TextColumn get rootParts => text().nullable()();

  /// 是否有记忆技巧
  BoolColumn get hasMnemonic => boolean().withDefault(const Constant(false))();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 主键
  @override
  Set<Column> get primaryKey => {id};
}

/// 用户单词进度表
class UserWordProgress extends Table {
  /// 单词ID
  TextColumn get wordId => text()();

  /// 词书ID
  TextColumn get bookId => text()();

  /// 难度因子 (SM-2算法)
  RealColumn get easinessFactor => real().withDefault(const Constant(2.5))();

  /// 复习间隔天数
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();

  /// 复习次数
  IntColumn get repetitions => integer().withDefault(const Constant(0))();

  /// 下次复习日期
  DateTimeColumn get nextReviewDate => dateTime()();

  /// 最近一次质量评分 (0-5)
  IntColumn get lastQuality => integer().withDefault(const Constant(0))();

  /// 是否已掌握
  BoolColumn get isMastered => boolean().withDefault(const Constant(false))();

  /// 复习债务
  IntColumn get reviewDebt => integer().withDefault(const Constant(0))();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// 主键
  @override
  Set<Column> get primaryKey => {wordId};
}

/// 游戏对局记录表
class GameSessions extends Table {
  /// 对局唯一ID
  IntColumn get id => integer().autoIncrement()();

  /// 词书ID
  TextColumn get bookId => text()();

  /// 领域ID（领域游戏时使用）
  TextColumn get domainId => text().nullable()();

  /// 游戏模式 (word/domain)
  TextColumn get gameMode => text().withDefault(const Constant('word'))();

  /// 网格大小 (3x3/4x4/5x5)
  IntColumn get gridSize => integer()();

  /// 匹配成功数
  IntColumn get matchCount => integer().withDefault(const Constant(0))();

  /// 错误次数
  IntColumn get errorCount => integer().withDefault(const Constant(0))();

  /// 使用提示次数
  IntColumn get hintCount => integer().withDefault(const Constant(0))();

  /// 游戏时长（毫秒）
  IntColumn get durationMs => integer()();

  /// 连击最高记录
  IntColumn get maxCombo => integer().withDefault(const Constant(0))();

  /// 得分
  IntColumn get score => integer().withDefault(const Constant(0))();

  /// 是否完成
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// 开始时间
  DateTimeColumn get startTime => dateTime()();

  /// 结束时间
  DateTimeColumn get endTime => dateTime().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 学习计划表
class LearningPlans extends Table {
  /// 计划唯一ID
  IntColumn get id => integer().autoIncrement()();

  /// 词书ID
  TextColumn get bookId => text()();

  /// 考试/目标日期
  DateTimeColumn get examDate => dateTime()();

  /// 每日学习时长（分钟）
  IntColumn get dailyMinutes => integer()();

  /// 每日新词目标
  IntColumn get dailyNewWords => integer().withDefault(const Constant(20))();

  /// 已学习天数
  IntColumn get learnedDays => integer().withDefault(const Constant(0))();

  /// 是否激活
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 应用数据库
@DriftDatabase(tables: [
  Words,
  UserWordProgress,
  GameSessions,
  LearningPlans,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 数据库版本
  @override
  int get schemaVersion => 1;

  /// 版本迁移
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 未来版本迁移逻辑
      },
    );
  }

  // ============ 词库查询 ============

  /// 获取词书所有单词
  Future<List<Word>> getWordsByBook(String bookId) {
    return (select(words)..where((w) => w.bookId.equals(bookId))).get();
  }

  /// 获取单个单词
  Future<Word?> getWordById(String wordId) {
    return (select(words)..where((w) => w.id.equals(wordId))).getSingleOrNull();
  }

  /// 批量插入单词
  Future<void> insertWords(List<WordsCompanion> wordList) async {
    await batch((batch) {
      batch.insertAll(words, wordList);
    });
  }

  // ============ 进度查询 ============

  /// 获取单词进度
  Future<UserWordProgressData?> getProgress(String wordId) {
    return (select(userWordProgress)..where((p) => p.wordId.equals(wordId)))
        .getSingleOrNull();
  }

  /// 获取词书所有进度
  Future<List<UserWordProgressData>> getProgressByBook(String bookId) {
    return (select(userWordProgress)..where((p) => p.bookId.equals(bookId)))
        .get();
  }

  /// 获取今日需复习的单词进度
  Future<List<UserWordProgressData>> getTodayReviewProgress(DateTime today) {
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return (select(userWordProgress)
          ..where((p) =>
              p.isMastered.equals(false) &
              p.nextReviewDate.isBetweenValues(todayStart, todayEnd)))
        .get();
  }

  /// 获取过期未复习的进度
  Future<List<UserWordProgressData>> getOverdueProgress(DateTime today) {
    final yesterday = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 1));

    return (select(userWordProgress)
          ..where((p) =>
              p.isMastered.equals(false) &
              p.nextReviewDate.isSmallerThanValue(yesterday)))
        .get();
  }

  /// 更新单词进度
  Future<void> updateProgress(UserWordProgressCompanion progress) async {
    await into(userWordProgress)
        .insert(progress, mode: InsertMode.insertOrReplace);
  }

  /// 批量更新进度
  Future<void> updateAllProgress(
      List<UserWordProgressCompanion> progressList) async {
    await batch((batch) {
      for (final p in progressList) {
        batch.insert(userWordProgress, p, mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// 获取已掌握单词数
  Future<int> getMasteredCount(String bookId) async {
    final count = (select(userWordProgress)
          ..where((p) => p.bookId.equals(bookId) & p.isMastered.equals(true)))
        .get();
    final list = await count;
    return list.length;
  }

  /// 获取已学习单词数
  Future<int> getLearnedCount(String bookId) async {
    final count =
        (select(userWordProgress)..where((p) => p.bookId.equals(bookId))).get();
    final list = await count;
    return list.length;
  }

  // ============ 游戏记录 ============

  /// 创建游戏记录
  Future<int> createGameSession(GameSessionsCompanion session) async {
    return await into(gameSessions).insert(session);
  }

  /// 更新游戏记录
  Future<void> updateGameSession(GameSessionsCompanion session) async {
    await (update(gameSessions)..where((s) => s.id.equals(session.id.value)))
        .write(session);
  }

  /// 获取最近游戏记录
  Future<List<GameSession>> getRecentSessions(int limit) {
    return (select(gameSessions)
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 获取用户统计数据
  Future<GameStats> getGameStats() async {
    final sessions = await select(gameSessions).get();

    if (sessions.isEmpty) {
      return GameStats(
        totalGames: 0,
        totalMatches: 0,
        totalErrors: 0,
        totalDurationMs: 0,
        avgScore: 0,
        maxCombo: 0,
      );
    }

    final totalMatches = sessions.fold(0, (sum, s) => sum + s.matchCount);
    final totalErrors = sessions.fold(0, (sum, s) => sum + s.errorCount);
    final totalDurationMs = sessions.fold(0, (sum, s) => sum + s.durationMs);
    final avgScore =
        sessions.fold(0, (sum, s) => sum + s.score) / sessions.length;
    final maxCombo =
        sessions.fold(0, (max, s) => s.maxCombo > max ? s.maxCombo : max);

    return GameStats(
      totalGames: sessions.length,
      totalMatches: totalMatches,
      totalErrors: totalErrors,
      totalDurationMs: totalDurationMs,
      avgScore: avgScore.round(),
      maxCombo: maxCombo,
    );
  }

  // ============ 学习计划 ============

  /// 获取当前激活的学习计划
  Future<LearningPlan?> getActivePlan() {
    return (select(learningPlans)..where((p) => p.isActive.equals(true)))
        .getSingleOrNull();
  }

  /// 创建学习计划
  Future<int> createPlan(LearningPlansCompanion plan) async {
    // 先禁用其他计划
    await (update(learningPlans)..where((p) => p.isActive.equals(true)))
        .write(const LearningPlansCompanion(isActive: Value(false)));
    return await into(learningPlans).insert(plan);
  }

  /// 更新学习计划
  Future<void> updatePlan(LearningPlansCompanion plan) async {
    await (update(learningPlans)..where((p) => p.id.equals(plan.id.value)))
        .write(plan);
  }

  /// 增加学习天数
  Future<void> incrementLearnedDays(int planId) async {
    final plan = await (select(learningPlans)
          ..where((p) => p.id.equals(planId)))
        .getSingle();

    await (update(learningPlans)..where((p) => p.id.equals(planId)))
        .write(LearningPlansCompanion(
      learnedDays: Value(plan.learnedDays + 1),
      updatedAt: Value(DateTime.now()),
    ));
  }
}

/// 游戏统计数据
class GameStats {
  final int totalGames;
  final int totalMatches;
  final int totalErrors;
  final int totalDurationMs;
  final int avgScore;
  final int maxCombo;

  GameStats({
    required this.totalGames,
    required this.totalMatches,
    required this.totalErrors,
    required this.totalDurationMs,
    required this.avgScore,
    required this.maxCombo,
  });
}

/// 打开数据库连接
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wordmatch.db'));
    return NativeDatabase.createInBackground(file);
  });
}
