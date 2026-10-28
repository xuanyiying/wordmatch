import 'package:flutter_test/flutter_test.dart';
import 'package:wordmatch/features/feed/domain/services/article_markdown_parser.dart';

void main() {
  group('ArticleMarkdownParser 段落提取', () {
    test('普通段落：剥离 inline 标记，链接保留文本，行内代码记区间', () {
      final r = ArticleMarkdownParser.parse(
          'This is **bold** and a [link](https://x.com) and `var x`.');
      expect(r.blocks, hasLength(1));
      expect(r.prose, hasLength(1));
      expect(r.blocks.first.sections, [isA<ReaderProse>()]);
      expect(r.prose.single,
          'This is bold and a link and var x.');
      // `var x` 区间（相对纯文本）
      expect(r.codeRanges.single.single,
          (start: 'This is bold and a link and '.length,
           end: 'This is bold and a link and var x'.length));
    });

    test('紧凑/宽松列表的每个列表项都产出 prose', () {
      final tight = ArticleMarkdownParser.parse(
          '- first item prose\n- second item prose\n- third item prose');
      expect(tight.blocks, hasLength(1));
      final list0 = tight.blocks.first.sections.single;
      expect(list0, isA<ReaderList>().having((l) => l.ordered, 'ordered', false));
      expect((list0 as ReaderList).items, hasLength(3));
      expect(tight.prose, [
        'first item prose',
        'second item prose',
        'third item prose',
      ]);

      final loose = ArticleMarkdownParser.parse(
          '- one loose item\n\n- two loose item');
      final list1 = loose.blocks.first.sections.single as ReaderList;
      expect(list1.items, hasLength(2));
      expect(loose.prose, ['one loose item', 'two loose item']);
    });

    test('有序列表标记 ordered', () {
      final r = ArticleMarkdownParser.parse('1. alpha sentence\n2. beta sentence');
      final list = r.blocks.first.sections.single as ReaderList;
      expect(list.ordered, true);
      expect(list.items, hasLength(2));
    });

    test('嵌套列表递归且文本按序提取', () {
      final r = ArticleMarkdownParser.parse(
          '- outer one\n  - inner alpha\n  - inner beta\n- outer two');
      final list = r.blocks.first.sections.single as ReaderList;
      expect(list.items, hasLength(2));
      // 第一项：prose + 嵌套列表
      expect(list.items[0].blocks[0], isA<ReaderProse>());
      final nested = list.items[0].blocks[1] as ReaderList;
      expect(nested.items, hasLength(2));
      expect(r.prose, ['outer one', 'inner alpha', 'inner beta', 'outer two']);
    });

    test('引用块内段落产出 prose', () {
      final r = ArticleMarkdownParser.parse(
          '> This is a quoted sentence with several words.');
      final quote = r.blocks.first.sections.single;
      expect(quote, isA<ReaderQuote>());
      expect((quote as ReaderQuote).children.single, isA<ReaderProse>());
      expect(r.prose.single,
          'This is a quoted sentence with several words.');
    });

    test('标题紧邻段落（无空行）时两个块都保留', () {
      final r = ArticleMarkdownParser.parse(
          '# Heading Here\nA paragraph immediately after the heading line.');
      expect(r.blocks, hasLength(2));
      expect(r.blocks[0].sections.single, isA<ReaderHeading>());
      expect(r.blocks[1].sections.single, isA<ReaderProse>());
      final h = r.blocks[0].sections.single as ReaderHeading;
      expect(h.level, 1);
      expect(h.text, 'Heading Here');
    });

    test('多块之间 prose 序号按渲染顺序连续', () {
      final r = ArticleMarkdownParser.parse([
        'First paragraph sentence.',
        '',
        '- list item alpha',
        '- list item beta',
        '',
        '> quoted paragraph text',
      ].join('\n'));
      expect(r.prose, [
        'First paragraph sentence.',
        'list item alpha',
        'list item beta',
        'quoted paragraph text',
      ]);

      Iterable<int> proseIndices(ReaderSection s) => switch (s) {
            ReaderProse() => [s.proseIndex],
            ReaderList() => [
                for (final item in s.items)
                  for (final b in item.blocks) ...proseIndices(b),
              ],
            ReaderQuote() => [
                for (final c in s.children) ...proseIndices(c),
              ],
            _ => const <int>[],
          };

      final indices = [
        for (final b in r.blocks)
          for (final s in b.sections) ...proseIndices(s),
      ];
      expect(indices, [0, 1, 2, 3]);
    });

    test('围栏代码块整块退回 MarkdownBody', () {
      final md = 'text before code.\n\n```dart\nvoid main() {}\n```';
      final r = ArticleMarkdownParser.parse(md);
      // 两个块：prose + fallback
      expect(r.blocks[0].sections, [isA<ReaderProse>()]);
      expect(r.blocks[1].sections, isEmpty);
      expect(r.blocks[1].raw, contains('void main'));
    });

    test('松散列表三项（空行分隔）不丢项', () {
      final r = ArticleMarkdownParser.parse(
          '- first item\n\n- second item\n\n- third item\n');
      expect(r.blocks, hasLength(1));
      final list = r.blocks.single.sections.single as ReaderList;
      expect(list.items, hasLength(3));
      expect(r.prose, ['first item', 'second item', 'third item']);
    });

    test('引用块内多段都产出 prose', () {
      final r = ArticleMarkdownParser.parse('> para one\n>\n> para two');
      final quote = r.blocks.single.sections.single as ReaderQuote;
      expect(quote.children, [isA<ReaderProse>(), isA<ReaderProse>()]);
      expect(r.prose, ['para one', 'para two']);
    });

    test('列表项含代码块时整个列表退回，原始片段保留列表标记', () {
      final md = '- do a thing\n\n  ```dart\n  var x = 1;\n  ```\n\n- next bullet';
      final r = ArticleMarkdownParser.parse(md);
      expect(r.blocks.single.sections, isEmpty);
      final raw = r.blocks.single.raw;
      expect(raw, contains('- do a thing'));
      expect(raw, contains('```dart'));
      expect(raw, contains('var x = 1;'));
      expect(raw, contains('- next bullet'));
    });

    test('围栏代码块含空行仍是一个 fallback 块，后续段落正常标注', () {
      final md = '```dart\nvoid a() {}\n\nvoid b() {}\n```\n\nafter block prose.';
      final r = ArticleMarkdownParser.parse(md);
      expect(r.blocks, hasLength(2));
      expect(r.blocks[0].sections, isEmpty);
      expect(r.blocks[0].raw, contains('void b() {}'));
      expect(r.blocks[1].sections.single, isA<ReaderProse>());
    });

    test('含图片的段落退回 MarkdownBody（不退化成 alt 文本）', () {
      final r =
          ArticleMarkdownParser.parse('![logo](https://x.com/a.png)');
      expect(r.blocks.single.sections, isEmpty);
      expect(r.prose, isEmpty);
    });

    test('列表项内行内代码记 skip 区间', () {
      final r = ArticleMarkdownParser.parse('- call `runApp()` now please');
      final list = r.blocks.first.sections.single as ReaderList;
      expect(list.items.single.blocks.single, isA<ReaderProse>());
      expect(r.prose.single, 'call runApp() now please');
      expect(r.codeRanges.single.single.start, 'call '.length);
    });

    test('hr 产出分隔线 section', () {
      final r = ArticleMarkdownParser.parse(
          'A sentence before the line.\n\n---\n\nA sentence after it.');
      expect(r.blocks[1].sections.single, isA<ReaderHr>());
    });

    test('表格整块退回 MarkdownBody', () {
      final md = '| a | b |\n|---|---|\n| 1 | 2 |';
      final r = ArticleMarkdownParser.parse(md);
      expect(r.blocks.single.sections, isEmpty);
    });
  });
}
