import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordmatch/core/theme/card_theme.dart';
import 'package:wordmatch/features/game/data/models/game_card.dart';
import 'package:wordmatch/features/game/presentation/widgets/card_widget.dart';

void main() {
  group('CardWidget', () {
    testWidgets('renders card text', (WidgetTester tester) async {
      const card = GameCard(
        itemId: 'word_1',
        type: CardType.typeA,
        text: 'hello',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardWidget(
              card: card,
              width: 120,
              height: 120,
              themeType: CardThemeType.academic,
            ),
          ),
        ),
      );

      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('tapping selected card calls onTap',
        (WidgetTester tester) async {
      var tapped = false;
      const card = GameCard(
        itemId: 'word_1',
        type: CardType.typeB,
        text: '你好',
        state: CardState.selected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardWidget(
              card: card,
              width: 120,
              height: 120,
              themeType: CardThemeType.academic,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('你好'));
      expect(tapped, true);
    });

    testWidgets('matched card shows line-through text',
        (WidgetTester tester) async {
      const card = GameCard(
        itemId: 'word_1',
        type: CardType.typeA,
        text: 'hello',
        state: CardState.matched,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardWidget(
              card: card,
              width: 120,
              height: 120,
              themeType: CardThemeType.academic,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('hello'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('splits typeB meaning by semicolon into two lines',
        (WidgetTester tester) async {
      const card = GameCard(
        itemId: 'word_2',
        type: CardType.typeB,
        text: '放弃；抛弃',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardWidget(
              card: card,
              width: 120,
              height: 120,
              themeType: CardThemeType.academic,
            ),
          ),
        ),
      );

      expect(find.text('放弃'), findsOneWidget);
      expect(find.text('抛弃'), findsOneWidget);
      expect(find.text('放弃；抛弃'), findsNothing);
    });

    testWidgets('randomly picks two meanings when more than two exist',
        (WidgetTester tester) async {
      const card = GameCard(
        itemId: 'word_3',
        type: CardType.typeB,
        text: '放弃；抛弃；遗弃',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardWidget(
              card: card,
              width: 120,
              height: 120,
              themeType: CardThemeType.academic,
            ),
          ),
        ),
      );

      // 完整原始文本不应出现
      expect(find.text('放弃；抛弃；遗弃'), findsNothing);

      // 只显示恰好 2 条释义
      final candidates = {'放弃', '抛弃', '遗弃'};
      var shownCount = 0;
      for (final candidate in candidates) {
        final found = find.text(candidate);
        if (found.evaluate().isNotEmpty) {
          shownCount++;
          expect(found, findsOneWidget);
        }
      }
      expect(shownCount, 2);
    });

    testWidgets('does not split typeA text by semicolon',
        (WidgetTester tester) async {
      const card = GameCard(
        itemId: 'word_4',
        type: CardType.typeA,
        text: 'a;b',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardWidget(
              card: card,
              width: 120,
              height: 120,
              themeType: CardThemeType.academic,
            ),
          ),
        ),
      );

      expect(find.text('a;b'), findsOneWidget);
      expect(find.text('a'), findsNothing);
      expect(find.text('b'), findsNothing);
    });

    testWidgets('does not show phonetic on typeA card',
        (WidgetTester tester) async {
      const card = GameCard(
        itemId: 'word_5',
        type: CardType.typeA,
        text: 'abandon',
        phonetic: "ə'bændən",
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardWidget(
              card: card,
              width: 120,
              height: 120,
              themeType: CardThemeType.academic,
            ),
          ),
        ),
      );

      expect(find.text('abandon'), findsOneWidget);
      expect(find.text("ə'bændən"), findsNothing);
    });

    testWidgets('strips part of speech prefix from meaning',
        (WidgetTester tester) async {
      const card = GameCard(
        itemId: 'word_6',
        type: CardType.typeB,
        text: 'vt. 放弃；抛弃',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardWidget(
              card: card,
              width: 120,
              height: 120,
              themeType: CardThemeType.academic,
            ),
          ),
        ),
      );

      expect(find.text('放弃'), findsOneWidget);
      expect(find.text('抛弃'), findsOneWidget);
      expect(find.text('vt. 放弃'), findsNothing);
      expect(find.text('vt. 放弃；抛弃'), findsNothing);
    });
  });
}
