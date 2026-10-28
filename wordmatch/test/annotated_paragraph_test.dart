import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordmatch/features/feed/data/services/dictionary_service.dart';
import 'package:wordmatch/features/feed/domain/services/annotation_models.dart';
import 'package:wordmatch/features/feed/presentation/widgets/annotated_paragraph.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildAnnotatedParagraph 渲染→原文映射', () {
    test('普通文本逐字符映射，WidgetSpan 占位符只占 1 个偏移', () {
      final spans = [
        const WordSpan('Hello ', WordStatus.graduated),
        const WordSpan('world', WordStatus.learning,
            rawWord: 'world', contextGloss: '世界'),
      ];
      final para = buildAnnotatedParagraph(
        spans,
        base: const TextStyle(fontSize: 16),
        onTap: (_) {},
      );

      // 渲染缓冲区 = 'Hello '(6) + 1 个 WidgetSpan 占位符 = 7 字符。
      // 词文 world 在 WidgetSpan 子组件里渲染，不占段落缓冲区偏移。
      expect(para.renderToSource, hasLength(7));
      // 'Hello ' → 原文 0..5
      for (var i = 0; i < 6; i++) {
        expect(para.renderToSource[i], i);
      }
      // 占位符 → 所属标注词的原文起点
      expect(para.renderToSource[6], 6);
      expect(para.placeholderWords, {6: 'world'});
      expect(para.words, {'world'});
    });

    test('标注词在段落中间时，后续单词取词不偏移（回归）', () {
      // 原文：t0 h1 e2 ' '3 q4 u5 i6 c7 k8 ' '9 b10 r11 o12 w13 n14
      //       ' '15 f16 o17 x18
      const source = 'the quick brown fox';
      final spans = [
        const WordSpan('the ', WordStatus.graduated),
        const WordSpan('quick', WordStatus.unfamiliar,
            rawWord: 'quick', contextGloss: '快的'),
        const WordSpan(' brown fox', WordStatus.graduated),
      ];
      final para = buildAnnotatedParagraph(
        spans,
        base: const TextStyle(),
        onTap: (_) {},
      );

      // 缓冲区：'the '(4) + 占位符(1) + ' brown fox'(10) = 15
      expect(para.renderToSource, hasLength(15));
      expect(para.renderToSource[4], 4); // 占位符 → quick 词首

      // 长按占位符 → 标注词本身
      expect(para.wordAtRenderOffset(source, 4), 'quick');
      // 长按标注词之后的普通词，必须命中实际按下的词
      expect(para.wordAtRenderOffset(source, 6), 'brown');
      expect(para.wordAtRenderOffset(source, 7), 'brown');
      expect(para.wordAtRenderOffset(source, 13), 'fox');
      expect(para.wordAtRenderOffset(source, 14), 'fox');
      // 标注词之前的词
      expect(para.wordAtRenderOffset(source, 0), 'the');
    });

    test('多个标注词连续出现时映射仍然对齐（回归）', () {
      const source = 'a brave clever dog';
      final spans = [
        const WordSpan('a ', WordStatus.graduated),
        const WordSpan('brave', WordStatus.unfamiliar, rawWord: 'brave'),
        const WordSpan(' ', WordStatus.graduated),
        const WordSpan('clever', WordStatus.learning, rawWord: 'clever'),
        const WordSpan(' dog', WordStatus.graduated),
      ];
      final para = buildAnnotatedParagraph(
        spans,
        base: const TextStyle(),
        onTap: (_) {},
      );

      // 'a '(2) + 占位符(1) + ' '(1) + 占位符(1) + ' dog'(4) = 9
      expect(para.renderToSource, hasLength(9));
      expect(para.wordAtRenderOffset(source, 2), 'brave');
      expect(para.wordAtRenderOffset(source, 4), 'clever');
      expect(para.wordAtRenderOffset(source, 8), 'dog');
    });

    test('短语标注长按占位符返回整个短语', () {
      const source = 'to look forward to now';
      final spans = [
        const WordSpan('to ', WordStatus.graduated),
        const WordSpan('look forward to', WordStatus.unfamiliar,
            rawWord: 'look forward to', contextGloss: '期待'),
        const WordSpan(' now', WordStatus.graduated),
      ];
      final para = buildAnnotatedParagraph(
        spans,
        base: const TextStyle(),
        onTap: (_) {},
      );

      // 'to '(3) + 占位符(1) + ' now'(4) = 8
      expect(para.renderToSource, hasLength(8));
      expect(para.wordAtRenderOffset(source, 3), 'look forward to');
      // 短语之后的词不受影响
      expect(para.wordAtRenderOffset(source, 7), 'now');
    });

    test('wordAtRenderOffset：词内命中、空格 1 字符容错、单字母词', () {
      final spans = [
        const WordSpan('Hello ', WordStatus.graduated),
        const WordSpan('world', WordStatus.learning,
            rawWord: 'world', contextGloss: '世界'),
      ];
      final para = buildAnnotatedParagraph(
        spans,
        base: const TextStyle(),
        onTap: (_) {},
      );
      const source = 'Hello world';

      expect(para.wordAtRenderOffset(source, 0), 'Hello');
      // 按在词尾后的空格（原文索引 5，容错命中 Hello）
      expect(para.wordAtRenderOffset(source, 5), 'Hello');
      // 按在占位符上 → 命中所属标注词
      expect(para.wordAtRenderOffset(source, 6), 'world');
      // 超界 clamp 到占位符
      expect(para.wordAtRenderOffset(source, 999), 'world');

      // 单字母词 a / I 也能取到
      expect(
        buildAnnotatedParagraph(
          const [WordSpan('I am a dog', WordStatus.graduated)],
          base: const TextStyle(),
          onTap: (_) {},
        ).wordAtRenderOffset('I am a dog', 0),
        'I',
      );
    });
  });

  group('WidgetSpan 划线下方括注渲染', () {
    testWidgets('括注占位显示在词下方，点击标注词触发 onTap', (tester) async {
      var tapped = '';
      final spans = [
        const WordSpan('Hello ', WordStatus.graduated),
        const WordSpan('world', WordStatus.learning,
            rawWord: 'world', contextGloss: '世界'),
      ];
      final para = buildAnnotatedParagraph(
        spans,
        base: const TextStyle(fontSize: 16),
        onTap: (w) => tapped = w,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RichText(text: para.root),
          ),
        ),
      ));

      // 词与括注各自渲染为 Text（括注在词的正下方，占布局空间）
      expect(find.text('world'), findsOneWidget);
      expect(find.text('世界'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 括注在词下方
      final wordTop = tester.getTopLeft(find.text('world')).dy;
      final glossTop = tester.getTopLeft(find.text('世界')).dy;
      expect(glossTop, greaterThan(wordTop));

      await tester.tap(find.text('world'));
      expect(tapped, 'world');
    });
  });

  group('DictionaryService.splitDefinitions', () {
    test('d 无词性前缀时用 pos 字段补首条', () {
      expect(DictionaryService.splitDefinitions('n.', '建议；忠告'),
          ['n. 建议', '忠告']);
    });

    test('d 自带词性前缀时不重复加', () {
      expect(DictionaryService.splitDefinitions('', 'v.授予；授予物 n.授予物'),
          ['v.授予', '授予物 n.授予物']);
    });

    test('空释义返回空列表', () {
      expect(DictionaryService.splitDefinitions('n.', ''), isEmpty);
    });

    test('逗号/全角分隔符也拆分', () {
      expect(DictionaryService.splitDefinitions('adj.', '重要的, 严重的'),
          ['adj. 重要的', '严重的']);
    });
  });
}
