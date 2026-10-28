import 'package:flutter_test/flutter_test.dart';
import 'package:wordmatch/features/feed/domain/services/annotation_models.dart';
import 'package:wordmatch/features/feed/domain/services/local_annotation_engine.dart';

void main() {
  final bookWords = {
    'abandon', 'ubiquitous', 'ephemeral', 'pragmatic', 'meticulous',
    'resilient', 'ambiguous', 'inevitable', 'paradigm', 'nuance',
    'stigma', 'candid', 'diligent', 'empathy',
  };
  final engine = LocalAnnotationEngine(
    masteredWords: {'known'},
    learningWords: {'study'},
    bookWords: bookWords,
  );

  group('LocalAnnotationEngine', () {
    test('已掌握词不标注，学习中的词浅色高亮', () {
      final spans = engine.processParagraph(
          'I know the study plan is good.');
      final annotated = spans.where((s) => s.isAnnotated).toList();
      expect(annotated.map((s) => s.rawWord.toLowerCase()),
          contains('study'));
      expect(
          annotated.map((s) => s.rawWord.toLowerCase()), isNot(contains('know')));
    });

    test('当前词书内未学习的词标注为 unfamiliar', () {
      final spans = engine.processParagraph('The paradigm shift was inevitable.');
      final annotated =
          spans.where((s) => s.status == WordStatus.unfamiliar).toList();
      expect(annotated.length, 2);
    });

    test('密度控制：生词超过上限时每段最多标注 8 个', () {
      final text = bookWords
          .map((w) => 'The $w is here.')
          .join(' '); // 14 个书内生词
      final spans = engine.processParagraph(text);
      final annotated = spans.where((s) => s.isAnnotated).toList();
      expect(annotated.length, 8);
      // unfamiliar 优先保留
      expect(annotated.every((s) => s.status == WordStatus.unfamiliar), isTrue);
    });

    test('AI 强制短语整体标注并携带语境义项', () {
      final spans = engine.processParagraph(
        'I look forward to the meeting.',
        forcedGlosses: {'look forward to': '期待'},
      );
      final phraseSpan = spans.firstWhere((s) => s.rawWord == 'look forward to');
      expect(phraseSpan.contextGloss, '期待');
      expect(phraseSpan.status, WordStatus.unfamiliar);
      // 短语整体为一个 span，不再单独标 look/forward/to
      expect(spans.any((s) => s.rawWord == 'look'), isFalse);
    });

    test('大小写不敏感匹配 AI 短语', () {
      final spans = engine.processParagraph(
        'She LOOK FORWARD TO it.',
        forcedGlosses: {'Look Forward To': '期待'},
      );
      expect(
          spans.any((s) => s.rawWord.toLowerCase() == 'look forward to'),
          isTrue);
    });

    test('常用词过滤：词书内的高频基础词不自动标注，学习中除外', () {
      final filtered = LocalAnnotationEngine(
        masteredWords: const {},
        learningWords: const {'accept'},
        bookWords: const {'about', 'accept', 'paradigm'},
        commonWords: const {'about', 'accept'},
      );
      final spans = filtered.processParagraph('About accept and paradigm.');
      final annotated = spans
          .where((s) => s.isAnnotated)
          .map((s) => s.rawWord.toLowerCase())
          .toList();
      // about：常用词且未在学 → 不标；accept：虽常用但学习中 → 保留；
      // paradigm：非常用词书词 → 标注
      expect(annotated, isNot(contains('about')));
      expect(annotated, contains('accept'));
      expect(annotated, contains('paradigm'));
    });

    test('词形还原：正文屈折形式命中词书原形', () {
      final lemmaEngine = LocalAnnotationEngine(
        masteredWords: const {'known'},
        learningWords: const {'study'},
        bookWords: const {'test', 'run', 'city'},
      );
      final spans = lemmaEngine.processParagraph(
          'The tests ran across the city.');
      final annotated = spans
          .where((s) => s.isAnnotated)
          .map((s) => s.rawWord.toLowerCase())
          .toList();
      // tests/test、ran/run、city 都应命中（展示保持原文词形）；
      // the 停用词、across 不在任何表 → 不标
      expect(annotated, contains('tests'));
      expect(annotated, contains('ran'));
      expect(annotated, contains('city'));
      expect(annotated, isNot(contains('the')));
      expect(annotated, isNot(contains('across')));
    });

    test('词形还原：正文屈折形式命中已掌握表', () {
      final lemmaEngine = LocalAnnotationEngine(
        masteredWords: const {'walk'},
        learningWords: const {},
        bookWords: const {},
      );
      final spans =
          lemmaEngine.processParagraph('She walked home.');
      expect(spans.any((s) => s.rawWord.toLowerCase() == 'walked'), isFalse);
    });

    test('AI 词形对齐：AI 返回原形、原文是屈折形式时仍锚定', () {
      final spans = engine.processParagraph(
        'The paradigm shift was inevitable.',
        forcedGlosses: {'paradigm': '范式'},
      );
      final phraseSpan =
          spans.firstWhere((s) => s.rawWord.toLowerCase() == 'paradigm');
      expect(phraseSpan.contextGloss, '范式');

      // AI 返回原形 paradigms（原文是 paradigm）——精确匹配失败后走词形对齐
      final aligned = engine.processParagraph(
        'The paradigm shift was inevitable.',
        forcedGlosses: {'paradigms': '范式'},
      );
      expect(
          aligned.any((s) => s.rawWord.toLowerCase() == 'paradigm'), isTrue);
    });

    test('AI 强制区间互相嵌套时按长优先去重，文本不重复', () {
      const text = 'I look forward to the meeting.';
      final spans = engine.processParagraph(
        text,
        forcedGlosses: {'look forward': '期待', 'look forward to': '期待'},
      );
      // 拼接文本必须与原文一致（重叠区间不得重复输出，否则长按偏移连带错位）
      expect(spans.map((s) => s.text).join(), text);
      // 长短语优先保留，被其覆盖的子短语丢弃
      expect(spans.any((s) => s.rawWord == 'look forward to'), isTrue);
      expect(spans.any((s) => s.rawWord == 'look forward'), isFalse);
    });

    test('同一 AI surface 多次出现只标首处', () {
      const text = 'Resilience matters; resilience pays.';
      final spans = engine.processParagraph(
        text,
        forcedGlosses: {'resilience': '韧性'},
      );
      expect(spans.map((s) => s.text).join(), text);
      final glossed = spans
          .where((s) => s.isAnnotated && (s.contextGloss?.isNotEmpty ?? false))
          .toList();
      expect(glossed.length, 1);
      expect(glossed.first.rawWord.toLowerCase(), 'resilience');
      // 第二处不再强制标注（resilience 不在词书，本地判定也不会标）：
      // 未标注文本不携带 rawWord（WordSpan 契约），第二处并入普通填充文本
      expect(
        spans.where((s) => s.rawWord.toLowerCase() == 'resilience').length,
        1,
      );
      expect(
        spans.any((s) => !s.isAnnotated && s.text.contains('resilience')),
        isTrue,
      );
    });

    test('合并语义：AI 未选中的词书词保留本地标注', () {
      final aiEngine = LocalAnnotationEngine(
        masteredWords: const {},
        learningWords: const {'study'},
        bookWords: const {'paradigm', 'inevitable'},
        commonWords: const {'about'},
      );
      final text = 'The paradigm about study was inevitable.';

      // AI 只选了 paradigm：inevitable 是词书学习目标，保留本地标注
      final spans = aiEngine.processParagraph(
        text,
        forcedGlosses: const {'paradigm': '范式'},
      );
      final annotated = spans
          .where((s) => s.isAnnotated)
          .map((s) => s.rawWord.toLowerCase())
          .toList();
      expect(annotated, contains('paradigm')); // AI 选中（带语境义）
      expect(annotated, contains('study')); // 用户学习中
      expect(annotated, contains('inevitable')); // 词书词不被 AI 空缺抹掉
      expect(annotated, isNot(contains('about'))); // 常用词仍过滤
    });

    test('AI 分析段落返回空 items 时，词书词照常本地标注', () {
      final aiEngine = LocalAnnotationEngine(
        masteredWords: const {},
        learningWords: const {},
        bookWords: const {'paradigm', 'inevitable'},
      );
      final spans = aiEngine.processParagraph(
        'The paradigm was inevitable.',
      );
      final annotated = spans
          .where((s) => s.isAnnotated)
          .map((s) => s.rawWord.toLowerCase())
          .toSet();
      expect(annotated, {'paradigm', 'inevitable'});
    });

    test('密度总预算：AI 强制区间挤占本地候选名额', () {
      final budgetEngine = LocalAnnotationEngine(
        masteredWords: const {},
        learningWords: const {},
        bookWords: const {
          'walpha', 'wbeta', 'wgamma', 'wdelta', 'rareone',
        },
        maxPerParagraph: 3,
      );
      final spans = budgetEngine.processParagraph(
        'walpha wbeta wgamma wdelta rareone',
        forcedGlosses: const {'look forward to': ''},
      );
      // 该段落没有短语可匹配，AI 强制区间为 0：本地预算 3
      final annotated = spans.where((s) => s.isAnnotated).toList();
      expect(annotated.length, 3);

      // 短语实际匹配 1 个区间时本地只剩 2 个名额
      final withPhrase = budgetEngine.processParagraph(
        'I look forward to walpha wbeta wgamma wdelta rareone',
        forcedGlosses: const {'look forward to': '期待'},
      );
      final annotatedWords = withPhrase
          .where((s) => s.isAnnotated)
          .map((s) => s.rawWord.toLowerCase())
          .toList();
      expect(annotatedWords, contains('look forward to'));
      expect(annotatedWords.length, 3); // 1 AI + 2 本地
    });

    test('aiCandidates：预筛只保留可能需要学习的词', () {
      final aiEngine = LocalAnnotationEngine(
        masteredWords: const {'known'},
        learningWords: const {'study'},
        bookWords: const {'paradigm'},
        commonWords: const {'about', 'tests'},
        stopwords: const {'the', 'of'},
      );
      final candidates =
          aiEngine.aiCandidates('The tests of known about study paradigm.');
      // known 已掌握、study 学习中、the/of 停用词、tests/about 常用词 → 跳过；
      // paradigm 词书未学 → 候选
      expect(candidates, ['paradigm']);
    });

    test('aiCandidates：词形还原后命中过滤集合的词不入候选', () {
      final aiEngine = LocalAnnotationEngine(
        masteredWords: const {'walk'},
        learningWords: const {},
        bookWords: const {'paradigm'},
        commonWords: const {'run'},
        stopwords: const {},
      );
      // walked→walk（已掌握）、runs→run（常用词）都还原命中后跳过
      final candidates = aiEngine.aiCandidates('walked runs paradigm');
      expect(candidates, ['paradigm']);
    });

    test('aiCandidates：全部词确定无需学习时返回空', () {
      final aiEngine = LocalAnnotationEngine(
        masteredWords: const {'known'},
        learningWords: const {},
        bookWords: const {},
        commonWords: const {'about'},
        stopwords: const {'the', 'of'},
      );
      expect(aiEngine.aiCandidates('The known about.'),
          isEmpty);
    });

    test('密度择优：超限时优先保留更生僻（词频排名更大）的词', () {
      final rankedEngine = LocalAnnotationEngine(
        masteredWords: const {},
        learningWords: const {},
        bookWords: const {
          'walpha', 'wbeta', 'wgamma', 'wdelta', // 排名已知
          'rareone', 'raretwo', 'rarethree', 'rarefour', // 不在频序表=最生僻
        },
        frequencyRanks: const {
          'walpha': 2100,
          'wbeta': 2200,
          'wgamma': 2300,
          'wdelta': 2400,
        },
        maxPerParagraph: 4,
      );
      final spans = rankedEngine.processParagraph(
        'walpha wbeta wgamma wdelta rareone raretwo rarethree rarefour.',
      );
      final annotated = spans
          .where((s) => s.isAnnotated)
          .map((s) => s.rawWord.toLowerCase())
          .toList();
      expect(annotated.length, 4);
      expect(annotated, containsAll(['rareone', 'raretwo', 'rarethree', 'rarefour']));
      expect(annotated, isNot(contains('walpha')));
    });
  });

  group('SemanticResult', () {
    test('JSON 往返解析', () {
      final json = {
        'paragraphs': [
          {
            'p': 0,
            'items': [
              {'t': 'gloss over', 'g': '敷衍，一笔带过', 'phrase': true},
              {'t': 'nuance', 'g': '细微差别', 'phrase': false},
            ],
          },
          {'p': 1, 'items': <Map<String, dynamic>>[]},
        ],
      };

      final result = SemanticResult.fromJson(json);
      expect(result.paragraphs.length, 2);
      expect(result.byParagraph[0]!.length, 2);
      expect(result.byParagraph[0]![0].surface, 'gloss over');
      expect(result.byParagraph[0]![0].phrase, isTrue);
      expect(result.byParagraph[1]!.length, 0);

      // toJson → fromJson 保持一致
      final restored = SemanticResult.fromJson(result.toJson());
      expect(restored.byParagraph[0]![1].gloss, '细微差别');
    });

    test('容错解析：字段缺失不抛异常', () {
      final result = SemanticResult.fromJson({
        'paragraphs': [
          {'items': null},
          {'p': 'bad', 'items': [{'t': ''}]},
        ],
      });
      expect(result.paragraphs.length, 2);
      expect(result.paragraphs[0].tokens, isEmpty);
      expect(result.paragraphs[1].tokens, isEmpty);
    });
  });
}
