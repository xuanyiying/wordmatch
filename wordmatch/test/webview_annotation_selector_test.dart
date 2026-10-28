import 'package:flutter_test/flutter_test.dart';
import 'package:wordmatch/features/feed/data/services/webview_highlight_script.dart';

void main() {
  // 公共词表：学习状态/词书/常用词与频序排名
  final mastered = {'old'};
  final learning = {'study'};
  final saved = {'look'};
  final book = {'paradigm', 'inevitable'};
  final common = {'industry'};
  final ranks = {'paradigm': 2500, 'inevitable': 3000};

  List<WebWordAnnotation> select(
    List<String> blocks, {
    int maxPerBlock = 8,
    Map<String, int>? freqRanks,
  }) {
    return selectWebviewAnnotations(
      blockTexts: blocks,
      masteredWords: mastered,
      learningWords: learning,
      savedWords: saved,
      bookWords: book,
      commonWords: common,
      frequencyRanks: freqRanks ?? ranks,
      maxPerBlock: maxPerBlock,
    );
  }

  test('学习中/已收藏强制标注为 learning，且不受预算挤占', () {
    final spans = select(['We study hard and look forward.'], maxPerBlock: 0);
    expect(spans.map((s) => s.word), unorderedEquals(['study', 'look']));
    expect(spans.every((s) => s.fadeLevel == 'learning'), isTrue);
  });

  test('已掌握/常用词/停用词不标注', () {
    expect(select(['The old industry is here.']), isEmpty);
  });

  test('词书未学词与频序表外生僻词标注为 new', () {
    final spans = select(['The paradigm shift was inevitable.']);
    final byWord = {for (final s in spans) s.word: s.fadeLevel};
    expect(byWord['paradigm'], 'new');
    expect(byWord['inevitable'], 'new');
    expect(byWord['shift'], 'new');
  });

  test('词形还原命中：屈折形式按原形判定', () {
    // looking → look（已收藏）；paradigms → paradigm（词书未学）
    final spans = select(['Looking at paradigms.'], maxPerBlock: 0);
    final byWord = {for (final s in spans) s.word: s.fadeLevel};
    expect(byWord['looking'], 'learning');
    expect(
      select(['Looking at paradigms.']).map((s) => s.word),
      containsAll(['looking', 'paradigms']),
    );
  });

  test('句中大写专名跳过，句首/块首大写仍作候选', () {
    final mid = select(['Using GitHub helps teams ship faster.']);
    expect(mid.map((s) => s.word), isNot(contains('github')));

    final start = select(['GitHub helps teams.']);
    expect(start.map((s) => s.word), contains('github'));
  });

  test('每块预算内按生僻度择优：频序表外 > 排名靠后 > 词更长', () {
    final freqRanks = {
      ...ranks,
      'alpha': 5000,
      'beta': 4000,
    };
    final spans = select(
      ['omega alpha beta.'],
      maxPerBlock: 2,
      freqRanks: freqRanks,
    );
    // omega 不在频序表 = 最生僻；alpha(5000) 次之；beta(4000) 落选
    expect(spans.map((s) => s.word), unorderedEquals(['omega', 'alpha']));
  });

  test('强制词挤占预算：候选名额 = 上限 - 强制词数', () {
    final spans = select(
      ['look alpha gamma yield beta.'],
      maxPerBlock: 2,
    );
    expect(spans.where((s) => s.fadeLevel == 'learning').map((s) => s.word),
        ['look']);
    expect(spans.where((s) => s.fadeLevel == 'new').length, 1);
  });

  test('同一词跨块只注入一次（脚本本就标注全部出现位置）', () {
    final spans = select([
      'obfuscate quickly.',
      'obfuscate again.',
    ]);
    expect(spans.where((s) => s.word == 'obfuscate').length, 1);
    expect(spans.where((s) => s.word == 'quickly').length, 1);
  });
}
