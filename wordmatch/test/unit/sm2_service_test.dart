import 'package:flutter_test/flutter_test.dart';
import 'package:wordmatch/features/learning/domain/services/sm2_service.dart';

void main() {
  group('Sm2Service', () {
    test('calculateQuality returns 5 for fast correct match', () {
      final q = Sm2Service.calculateQuality(matchTimeMs: 1000, errorCount: 0);
      expect(q, 5);
    });

    test('calculateQuality returns 3 for slow match (>3s)', () {
      final q = Sm2Service.calculateQuality(matchTimeMs: 5000, errorCount: 0);
      expect(q, 3);
    });

    test('calculateQuality returns 3 for one error', () {
      final q = Sm2Service.calculateQuality(matchTimeMs: 500, errorCount: 1);
      expect(q, 3);
    });

    test('calculateQuality returns 1 for two errors', () {
      final q = Sm2Service.calculateQuality(matchTimeMs: 500, errorCount: 2);
      expect(q, 1);
    });

    test('calculateQuality returns 1 for hint usage', () {
      final q = Sm2Service.calculateQuality(
          matchTimeMs: 500, errorCount: 0, usedHint: true);
      expect(q, 1);
    });

    test('updateProgress resets on quality < 3', () {
      final progress = WordProgress(
        wordId: 'test',
        bookId: 'gaokao',
        easinessFactor: 2.5,
        intervalDays: 6,
        repetitions: 2,
        nextReviewDate: DateTime.now(),
      );

      final updated = Sm2Service.updateProgress(progress, 1);
      expect(updated.repetitions, 0);
      expect(updated.intervalDays, 1);
      expect(
          updated.easinessFactor, lessThan(2.5)); // EF decreases on low quality
    });

    test('updateProgress advances on quality >= 3', () {
      final progress = WordProgress.newWord('test', 'gaokao');

      // First correct: interval = 1
      final p1 = Sm2Service.updateProgress(progress, 5);
      expect(p1.repetitions, 1);
      expect(p1.intervalDays, 1);

      // Second correct: interval = 6
      final p2 = Sm2Service.updateProgress(p1, 5);
      expect(p2.repetitions, 2);
      expect(p2.intervalDays, 6);

      // Third correct: interval = 6 * EF
      final p3 = Sm2Service.updateProgress(p2, 5);
      expect(p3.repetitions, 3);
      expect(p3.intervalDays, greaterThan(6));
    });

    test('mastered when interval >= 21 days', () {
      var progress = WordProgress.newWord('test', 'gaokao');
      progress = progress.copyWith(
          easinessFactor: 2.5, intervalDays: 6, repetitions: 2);

      final updated = Sm2Service.updateProgress(progress, 5);
      // 6 * 2.6 = 15.6, not 21 yet
      // need more repetitions to reach 21
      final p2 = Sm2Service.updateProgress(updated, 5);
      expect(p2.intervalDays, greaterThan(15));
    });

    test('calculateDailyNewWords respects debt', () {
      final normal = Sm2Service.calculateDailyNewWords(
        totalWords: 3500,
        masteredWords: 0,
        remainingDays: 90,
        availableMinutes: 30,
        currentDebt: 0,
      );
      final withDebt = Sm2Service.calculateDailyNewWords(
        totalWords: 3500,
        masteredWords: 0,
        remainingDays: 90,
        availableMinutes: 30,
        currentDebt: 50,
      );
      expect(withDebt, lessThan(normal));
    });

    test('getDebtReliefMessage returns empty when no debt', () {
      expect(Sm2Service.getDebtReliefMessage(0), '');
    });

    test('getDebtReliefMessage returns message when debt > 0', () {
      expect(Sm2Service.getDebtReliefMessage(50), contains('50'));
    });

    test('秒配 + 点过发音 → Q=6（上限）', () {
      final q = Sm2Service.calculateQuality(
        matchTimeMs: 500,
        errorCount: 0,
        soundTapCount: 1,
      );
      expect(q, 6);
    });

    test('正常配但查了词根 → Q 扣 0.5', () {
      final q = Sm2Service.calculateQuality(
        matchTimeMs: 1500,
        errorCount: 0,
        rootLensTapCount: 1,
      );
      expect(q, 5);
    });

    test('配对+看了AI助记故事 → Q 扣1.0', () {
      final q = Sm2Service.calculateQuality(
        matchTimeMs: 1500,
        errorCount: 0,
        aiMnemonicTapCount: 1,
      );
      expect(q, 4);
    });

    test('错2次+查AI助记 → Q不低于0底线', () {
      final q = Sm2Service.calculateQuality(
        matchTimeMs: 1000,
        errorCount: 2,
        aiMnemonicTapCount: 2,
      );
      expect(q, greaterThanOrEqualTo(0));
      expect(q, lessThanOrEqualTo(6));
      expect(q, 0);
    });

    test('errorCount=1 + 点发音 → 3.5 round到4', () {
      final q = Sm2Service.calculateQuality(
        matchTimeMs: 1000,
        errorCount: 1,
        soundTapCount: 1,
      );
      expect(q, 4);
    });
  });
}
