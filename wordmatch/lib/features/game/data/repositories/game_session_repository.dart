import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:wordmatch/features/wordbook/data/database/app_database.dart';

/// 游戏对局记录仓库（SQLite / Drift）
///
/// 对局记录是**无上限增长**的数据：每完成一局就新增一行，长期使用可达数万行。
/// 这类数据用 SharedPreferences 的整块 JSON 读写会越来越慢（每次全量序列化），
/// 因此改用 SQLite：单行增量写入，聚合统计（总局数/平均分/最高连击）交给
/// SQL 聚合函数，不必把全部记录载入内存。
///
/// 所有方法都做了异常兜底：数据库故障只记录日志，绝不打断正在进行的游戏。
class GameSessionRepository {
  GameSessionRepository({AppDatabase? database})
      : _database = database ?? AppDatabase();

  /// 全局单例：数据库连接在进程内只需要一份
  static final GameSessionRepository instance = GameSessionRepository();

  final AppDatabase _database;

  /// 记录一局已完成的游戏
  Future<int?> recordSession({
    required String bookId,
    String? domainId,
    String gameMode = 'word',
    required int gridSize,
    required int matchCount,
    required int errorCount,
    required int hintCount,
    required int durationMs,
    required int maxCombo,
    required int score,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    try {
      return await _database.createGameSession(GameSessionsCompanion.insert(
        bookId: bookId,
        domainId: Value(domainId),
        gameMode: Value(gameMode),
        gridSize: gridSize,
        matchCount: Value(matchCount),
        errorCount: Value(errorCount),
        hintCount: Value(hintCount),
        durationMs: durationMs,
        maxCombo: Value(maxCombo),
        score: Value(score),
        isCompleted: const Value(true),
        startTime: startTime,
        endTime: Value(endTime ?? DateTime.now()),
      ));
    } catch (e) {
      developer.log('GameSessionRepository: 对局记录写入失败', error: e);
      return null;
    }
  }

  /// 最近的若干局对战记录（按时间倒序）
  Future<List<GameSession>> recentSessions({int limit = 10}) async {
    try {
      return await _database.getRecentSessions(limit);
    } catch (e) {
      developer.log('GameSessionRepository: 对局记录读取失败', error: e);
      return const [];
    }
  }

  /// 汇总战绩（总局数 / 累计消除 / 累计错误 / 总时长 / 平均分 / 最高连击）
  Future<GameStats> stats() async {
    try {
      return await _database.getGameStats();
    } catch (e) {
      developer.log('GameSessionRepository: 战绩统计失败', error: e);
      return GameStats(
        totalGames: 0,
        totalMatches: 0,
        totalErrors: 0,
        totalDurationMs: 0,
        avgScore: 0,
        maxCombo: 0,
      );
    }
  }

  /// 关闭数据库连接（应用退出时调用）
  Future<void> dispose() => _database.close();
}
