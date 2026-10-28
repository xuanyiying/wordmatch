import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:wordmatch/features/learning/data/repositories/progress_storage.dart';
import 'package:wordmatch/features/learning/domain/services/sm2_service.dart';

/// 可计数的内存存储：记录每次落盘的 key，用于断言写盘次数
class _CountingStore extends InMemorySharedPreferencesStore {
  _CountingStore(super.data) : super.withData();

  final List<String> writes = [];

  /// 为 true 时所有写盘都会抛错，用于模拟落盘失败
  bool failWrites = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    // store 收到的是带 'flutter.' 前缀的 key
    writes.add(
        key.startsWith('flutter.') ? key.substring('flutter.'.length) : key);
    if (failWrites) {
      throw StateError('模拟写盘失败');
    }
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CountingStore store;

  /// 每个用例一份全新的存储与 ProgressStorage 实例，互不干扰
  Future<ProgressStorage> newStorage(
      [Map<String, Object> seed = const {}]) async {
    final prefixed = <String, Object>{
      for (final e in seed.entries) 'flutter.${e.key}': e.value,
    };
    store = _CountingStore(prefixed);
    SharedPreferencesStorePlatform.instance = store;
    // 重置 legacy 单例缓存，让下一次 getInstance 绑定到新 store
    SharedPreferences.resetStatic();
    final storage = ProgressStorage();
    await storage.init();
    return storage;
  }

  group('ProgressStorage 写合并', () {
    test('多次连续更新只落盘一次（不再逐次全量写盘）', () async {
      final storage = await newStorage();
      for (var i = 0; i < 10; i++) {
        await storage.updateProgress(WordProgress.newWord('w$i', 'gaokao'));
      }
      // 高频单条更新不阻塞调用方：此刻磁盘上还没有任何写入
      expect(store.writes.where((k) => k == 'word_progress'), isEmpty);

      await storage.flush();
      // 10 次更新合并为 1 次写盘，而不是 10 次
      expect(store.writes.where((k) => k == 'word_progress').length, 1);
    });

    test('updateAllProgress 整批只落盘一次', () async {
      final storage = await newStorage();
      await storage.updateAllProgress([
        for (var i = 0; i < 12; i++) WordProgress.newWord('w$i', 'gaokao'),
      ]);
      expect(store.writes.where((k) => k == 'word_progress').length, 1);
    });

    test('各数据域独立落盘：更新进度不牵连错词与每日历史', () async {
      final storage = await newStorage();
      await storage.updateProgress(WordProgress.newWord('w1', 'gaokao'));
      await storage.flush();

      expect(store.writes, contains('word_progress'));
      expect(store.writes, isNot(contains('wrong_words')));
      expect(store.writes, isNot(contains('daily_learning_history')));
    });

    test('落盘次数不随更新条数增长', () async {
      final storage = await newStorage();
      await storage.updateAllProgress([
        for (var i = 0; i < 3; i++) WordProgress.newWord('w$i', 'gaokao'),
      ]);
      final afterBatch = store.writes.length;
      await storage.updateAllProgress([
        for (var i = 3; i < 30; i++) WordProgress.newWord('w$i', 'gaokao'),
      ]);
      // 第二批 27 条仍然只增加常数次写盘
      expect(store.writes.length - afterBatch, lessThanOrEqualTo(3));
    });

    test('写盘失败时保留脏标记并在下次落盘补写', () async {
      final storage = await newStorage();
      await storage.updateProgress(WordProgress.newWord('w1', 'gaokao'));

      // 第一次落盘失败
      store.failWrites = true;
      await storage.flush();
      final failedAttempts =
          store.writes.where((k) => k == 'word_progress').length;
      expect(failedAttempts, greaterThan(0));

      // 失败后脏标记保留，恢复后再次落盘仍会写入并成功
      store.failWrites = false;
      await storage.flush();
      expect(store.writes.where((k) => k == 'word_progress').length,
          greaterThan(failedAttempts));

      // 数据最终落盘成功
      final next = ProgressStorage();
      await next.init();
      expect(next.getProgress('w1'), isNotNull);
    });
  });

  group('ProgressStorage 数据正确性', () {
    test('更新后可被新实例读回', () async {
      final storage = await newStorage();
      await storage.updateProgress(WordProgress.newWord('w1', 'gaokao'));
      await storage.flush();

      final next = ProgressStorage();
      await next.init();
      expect(next.getProgress('w1'), isNotNull);
      expect(next.getLearnedCount(), 1);
    });

    test('合并写盘不丢数据：20 条进度全部落盘', () async {
      final storage = await newStorage();
      for (var i = 0; i < 20; i++) {
        await storage.updateProgress(WordProgress.newWord('w$i', 'gaokao'));
      }
      await storage.flush();

      final next = ProgressStorage();
      await next.init();
      expect(next.getLearnedCount(), 20);
      expect(next.getProgress('w19'), isNotNull);
    });

    test('init 幂等：重复初始化不会把内存中的变更冲掉', () async {
      final storage = await newStorage();
      await storage.updateProgress(WordProgress.newWord('w1', 'gaokao'));
      await storage.init();
      expect(storage.getProgress('w1'), isNotNull);
    });

    test('flush 立即落盘待写数据', () async {
      final storage = await newStorage();
      await storage.updateProgress(WordProgress.newWord('w1', 'gaokao'));
      await storage.flush();

      final next = ProgressStorage();
      await next.init();
      expect(next.getProgress('w1'), isNotNull);
    });

    test('损坏的进度数据不会导致初始化失败', () async {
      final storage = await newStorage({'word_progress': 'not-json'});
      expect(storage.getLearnedCount(), 0);
      expect(storage.isInitialized, isTrue);
    });

    test('错词本增删可持久化', () async {
      final storage = await newStorage();
      await storage.addWrongWord(wordId: 'w1', bookId: 'gaokao');
      await storage.addWrongWord(wordId: 'w2', bookId: 'gaokao');
      expect(storage.getWrongWordCount(), 2);

      await storage.removeWrongWords(['w1']);
      expect(storage.getWrongWordCount(), 1);

      final next = ProgressStorage();
      await next.init();
      expect(next.getWrongWordCount(), 1);
      expect(next.getWrongWord('w2'), isNotNull);
    });

    test('学习后连续打卡天数递增', () async {
      final storage = await newStorage();
      expect(storage.getStreakDays(), 0);
      await storage.updateProgress(WordProgress.newWord('w1', 'gaokao'));
      expect(storage.getStreakDays(), 1);
    });

    test('每日学习历史可持久化', () async {
      final storage = await newStorage();
      await storage.recordDailyActivity(newWords: 3, minutes: 5);

      final next = ProgressStorage();
      await next.init();
      final history = next.getDailyHistory(1);
      expect(history.first.newWords, 3);
      expect(history.first.minutes, 5);
    });
  });
}
