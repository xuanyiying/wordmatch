import 'package:flutter_test/flutter_test.dart';
import 'package:wordmatch/features/game/domain/services/match_service.dart';
import 'package:wordmatch/features/game/domain/services/root_engine.dart';
import 'package:wordmatch/features/game/domain/services/difficulty_service.dart';
import 'package:wordmatch/features/game/data/models/game_card.dart';

void main() {
  group('MatchService', () {
    test('matching same itemId with different types returns match', () {
      final typeA = GameCard.typeA(itemId: 'test', text: 'test');
      final typeB = GameCard.typeB(itemId: 'test', text: '测试');
      final result =
          MatchService.checkMatch(firstCard: typeA, secondCard: typeB);
      expect(result.isMatch, true);
    });

    test('matching different itemId returns no match', () {
      final typeA = GameCard.typeA(itemId: 'test1', text: 'test');
      final typeB = GameCard.typeB(itemId: 'test2', text: '测试');
      final result =
          MatchService.checkMatch(firstCard: typeA, secondCard: typeB);
      expect(result.isMatch, false);
    });

    test('matching same type returns no match', () {
      final typeA1 = GameCard.typeA(itemId: 'test', text: 'test');
      final typeA2 = GameCard.typeA(itemId: 'test', text: 'test');
      final result =
          MatchService.checkMatch(firstCard: typeA1, secondCard: typeA2);
      expect(result.isMatch, false);
    });
  });

  group('RootEngine', () {
    test('analyzes word with prefix+root+suffix', () {
      // "prediction" -> suffix "tion" (longest match), then prefix "pre", root may be "dict"
      final result = RootEngine.analyze('prediction');
      expect(result.isValid, true);
      expect(result.prefix, 'pre');
      expect(result.suffix, 'tion'); // longest suffix match
    });

    test('analyzes word with prefix only', () {
      final result = RootEngine.analyze('unable');
      expect(result.prefix, 'un');
    });

    test('returns empty for short words', () {
      final result = RootEngine.analyze('a');
      expect(result.isValid, false);
    });

    test('formatted output joins parts with dash', () {
      final result = RootEngine.analyze('prediction');
      if (result.isValid) {
        expect(result.formatted, contains('-'));
      }
    });
  });

  group('DifficultyService', () {
    test('hasValidPath returns true for valid grid', () {
      final cards = [
        GameCard.typeA(itemId: 'a', text: 'a'),
        GameCard.typeB(itemId: 'a', text: 'A'),
        GameCard.typeA(itemId: 'b', text: 'b'),
        GameCard.typeB(itemId: 'b', text: 'B'),
      ];
      expect(DifficultyService.hasValidPath(cards), true);
    });

    test('hasValidPath returns false when all matched', () {
      final cards = [
        GameCard.typeA(itemId: 'a', text: 'a')
            .copyWith(state: CardState.matched),
        GameCard.typeB(itemId: 'a', text: 'A')
            .copyWith(state: CardState.matched),
      ];
      expect(DifficultyService.hasValidPath(cards), false);
    });

    test('findHintPair returns indices for valid pair', () {
      final cards = [
        GameCard.typeA(itemId: 'a', text: 'a'),
        GameCard.typeB(itemId: 'b', text: 'B'),
        GameCard.typeA(itemId: 'b', text: 'b'),
        GameCard.typeB(itemId: 'a', text: 'A'),
      ];
      final hint = DifficultyService.findHintPair(cards);
      expect(hint, isNotNull);
      expect(hint!.length, 2);
    });

    test('shouldShowHint returns true after 3 errors', () {
      expect(DifficultyService.shouldShowHint(3), true);
      expect(DifficultyService.shouldShowHint(2), false);
    });
  });
}
