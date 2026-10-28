import 'package:flutter_test/flutter_test.dart';
import 'package:wordmatch/features/feed/domain/services/word_lemmatizer.dart';

void main() {
  group('WordLemmatizer.candidates', () {
    // 命中辅助：还原候选包含期望原形
    bool restoresTo(String inflected, String lemma) =>
        WordLemmatizer.candidates(inflected).contains(lemma);

    test('不规则动词过去式/过去分词', () {
      expect(restoresTo('ran', 'run'), isTrue);
      expect(restoresTo('wrote', 'write'), isTrue);
      expect(restoresTo('written', 'write'), isTrue);
      expect(restoresTo('went', 'go'), isTrue);
      expect(restoresTo('thought', 'think'), isTrue);
      expect(restoresTo('better', 'good'), isTrue);
      // 扩展表覆盖
      expect(restoresTo('got', 'get'), isTrue);
      expect(restoresTo('gotten', 'get'), isTrue);
      expect(restoresTo('arose', 'arise'), isTrue);
      expect(restoresTo('dwelt', 'dwell'), isTrue);
      expect(restoresTo('wound', 'wind'), isTrue);
      expect(restoresTo('drank', 'drink'), isTrue);
      expect(restoresTo('underwent', 'undergo'), isTrue);
    });

    test('不规则名词复数与希腊拉丁来源', () {
      expect(restoresTo('criteria', 'criterion'), isTrue);
      expect(restoresTo('analyses', 'analysis'), isTrue);
      expect(restoresTo('phenomena', 'phenomenon'), isTrue);
      expect(restoresTo('indices', 'index'), isTrue);
      expect(restoresTo('oxen', 'ox'), isTrue);
      expect(restoresTo('hooves', 'hoof'), isTrue);
      // 歧义词规则兜底：bases→base（不指向 basis）
      expect(restoresTo('bases', 'base'), isTrue);
    });

    test('规则后缀：复数', () {
      expect(restoresTo('tests', 'test'), isTrue);
      expect(restoresTo('studies', 'study'), isTrue);
      expect(restoresTo('cities', 'city'), isTrue);
      expect(restoresTo('boxes', 'box'), isTrue);
      expect(restoresTo('classes', 'class'), isTrue);
      expect(restoresTo('matches', 'match'), isTrue);
      expect(restoresTo('leaves', 'leaf'), isTrue);
    });

    test('规则后缀：动词屈折', () {
      expect(restoresTo('walked', 'walk'), isTrue);
      expect(restoresTo('stopped', 'stop'), isTrue);
      expect(restoresTo('loved', 'love'), isTrue);
      expect(restoresTo('carried', 'carry'), isTrue);
      expect(restoresTo('running', 'run'), isTrue);
      expect(restoresTo('coding', 'code'), isTrue);
      expect(restoresTo('using', 'use'), isTrue);
    });

    test('规则后缀：比较级与副词', () {
      expect(restoresTo('faster', 'fast'), isTrue);
      expect(restoresTo('bigger', 'big'), isTrue);
      expect(restoresTo('largest', 'large'), isTrue);
      expect(restoresTo('quickly', 'quick'), isTrue);
      expect(restoresTo('happily', 'happy'), isTrue);
    });

    test('所有者格与 -es 名词复数', () {
      expect(restoresTo("company's", 'company'), isTrue);
      // 词干为不规则形式时连同原形一并给出
      expect(restoresTo("children's", 'child'), isTrue);
      expect(restoresTo('buses', 'bus'), isTrue);
      expect(restoresTo('viruses', 'virus'), isTrue);
      expect(restoresTo('focuses', 'focus'), isTrue);
      expect(restoresTo('echoes', 'echo'), isTrue);
      expect(restoresTo('tomatoes', 'tomato'), isTrue);
      expect(restoresTo('shoes', 'shoe'), isTrue);
      expect(restoresTo('cases', 'case'), isTrue);
      // 原 -sses/-ches 分支不回归
      expect(restoresTo('classes', 'class'), isTrue);
      expect(restoresTo('watches', 'watch'), isTrue);
    });

    test('-ing 特殊变形与误导候选防护', () {
      expect(restoresTo('dying', 'die'), isTrue);
      expect(restoresTo('lying', 'lie'), isTrue);
      expect(restoresTo('tying', 'tie'), isTrue);
      expect(restoresTo('vying', 'vie'), isTrue);
      // thing 的还原不得产出 the（否则误命中常用词表被过滤）
      expect(WordLemmatizer.candidates('thing'), isNot(contains('the')));
      // us→use 这类以 s 结尾的短词干不受防护影响
      expect(restoresTo('using', 'use'), isTrue);
    });

    test('非屈折词不产生误导候选', () {
      // class/status/axis 等非复数 -s 词不去 -s
      expect(WordLemmatizer.candidates('class'), isEmpty);
      expect(WordLemmatizer.candidates('status'), isEmpty);
      expect(WordLemmatizer.candidates('axis'), isEmpty);
      // 过短/无明显后缀的词
      expect(WordLemmatizer.candidates('cat'), isEmpty);
      expect(WordLemmatizer.candidates('paradigm'), isEmpty);
    });

    test('大小写不敏感', () {
      expect(restoresTo('Tests', 'test'), isTrue);
      expect(restoresTo('WROTE', 'write'), isTrue);
    });
  });
}
