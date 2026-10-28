import 'package:flutter_test/flutter_test.dart';
import 'package:wordmatch/features/feed/data/services/semantic_annotator_service.dart';

void main() {
  group('SemanticAnnotatorService.parseGlossResult', () {
    test('正常解析语境释义', () {
      final out = SemanticAnnotatorService.parseGlossResult({
        'glosses': [
          {'t': 'run', 'g': 'v. 经营'},
          {'t': 'bank', 'g': 'n. 河岸'},
        ],
      }, {'run', 'bank'});
      expect(out, {'run': 'v. 经营', 'bank': 'n. 河岸'});
    });

    test('word 大小写归一，拒绝请求词表外的词', () {
      final out = SemanticAnnotatorService.parseGlossResult({
        'glosses': [
          {'t': 'Run', 'g': 'v. 经营'},
          {'t': 'hello', 'g': '你好'},
        ],
      }, {'run'});
      expect(out, {'run': 'v. 经营'});
    });

    test('拒绝空释义与超长释义', () {
      final out = SemanticAnnotatorService.parseGlossResult({
        'glosses': [
          {'t': 'run', 'g': ''},
          {'t': 'bank', 'g': '这是一个远远超过十四个字符限制的冗长解释释义'},
          {'t': 'present', 'g': 'adj. 出席的'},
        ],
      }, {'run', 'bank', 'present'});
      expect(out, {'present': 'adj. 出席的'});
    });

    test('缺 glosses 字段或格式错误返回空', () {
      expect(SemanticAnnotatorService.parseGlossResult({}, {'run'}), isEmpty);
      expect(
        SemanticAnnotatorService.parseGlossResult({
          'glosses': 'bad',
        }, {'run'}),
        isEmpty,
      );
      expect(
        SemanticAnnotatorService.parseGlossResult({
          'glosses': [
            'not-a-map',
            {'t': 'run'},
          ],
        }, {'run'}),
        isEmpty,
      );
    });
  });

  group('SemanticAnnotatorService.planChunksForTest（整篇文章分块）', () {
    String chars(int n) => 'a' * n;

    test('空段落列表产出空块', () {
      expect(SemanticAnnotatorService.planChunksForTest(const []), isEmpty);
    });

    test('短文章一块装下，start 为 0', () {
      final chunks =
          SemanticAnnotatorService.planChunksForTest(['hello', 'world']);
      expect(chunks, hasLength(1));
      expect(chunks.single.start, 0);
      expect(chunks.single.texts, ['hello', 'world']);
    });

    test('超预算切成多块，start 为全局段落序号且连续', () {
      final paragraphs = [chars(3000), chars(3000), chars(1000), chars(500)];
      final chunks = SemanticAnnotatorService.planChunksForTest(paragraphs);
      expect(chunks.length, greaterThan(1));
      expect(chunks.first.start, 0);
      // 相邻块首尾相接
      for (var i = 1; i < chunks.length; i++) {
        expect(chunks[i].start,
            chunks[i - 1].start + chunks[i - 1].texts.length);
      }
      // 所有段落都被覆盖（长文章尾部不再丢失）
      final total = chunks.fold<int>(0, (n, c) => n + c.texts.length);
      expect(total, paragraphs.length);
      expect([for (final c in chunks) ...c.texts], paragraphs);
    });

    test('单段超过块上限时独立成块并截断，不丢段', () {
      final paragraphs = [chars(100), chars(5000), chars(100)];
      final chunks = SemanticAnnotatorService.planChunksForTest(paragraphs);
      final big = chunks.singleWhere((c) => c.start == 1);
      expect(big.texts, hasLength(1));
      expect(big.texts.single.length, 4000);
      final covered = {
        for (final c in chunks)
          for (var i = 0; i < c.texts.length; i++) c.start + i,
      };
      expect(covered, {0, 1, 2});
    });

    test('传 candidates 时空候选段跳过，其余段携带候选', () {
      final paragraphs = ['with words', 'no candidate', 'more words'];
      final candidates = [
        ['words'],
        const <String>[],
        ['more'],
      ];
      final chunks =
          SemanticAnnotatorService.planChunksForTest(paragraphs, candidates);
      expect(chunks, hasLength(1));
      expect(chunks.single.start, 0);
      // 零候选段被整段跳过（不发请求）
      expect(chunks.single.texts, ['with words', 'more words']);
      expect(
          chunks.single.candidates,
          const [
            ['words'],
            ['more'],
          ]);
    });

    test('全部段落零候选时产出空块列表', () {
      final chunks = SemanticAnnotatorService.planChunksForTest(
        ['a', 'b'],
        const [
          <String>[],
          <String>[],
        ],
      );
      expect(chunks, isEmpty);
    });

    test('不传 candidates 时不跳过任何段落', () {
      final chunks =
          SemanticAnnotatorService.planChunksForTest(['hello', 'world']);
      expect(chunks.single.texts, ['hello', 'world']);
      expect(chunks.single.candidates, isEmpty);
    });
  });
}
