import 'package:flutter_test/flutter_test.dart';
import 'package:wordmatch/core/audio/sherpa_tts_engine.dart';

void main() {
  group('SherpaTtsEngine 长文本分句逻辑', () {
    test('按句尾标点正确切分长文本', () {
      const text =
          'Hello world. This is a test sentence! How are you today? Wonderful...';
      final parts = SherpaTtsEngine.splitSentences(text);
      expect(parts, hasLength(4));
      expect(parts[0], 'Hello world.');
      expect(parts[1], 'This is a test sentence!');
      expect(parts[2], 'How are you today?');
      expect(parts[3], 'Wonderful...');
    });

    test('短文本不切分，保持整段', () {
      const text = 'A short sentence here.';
      final parts = SherpaTtsEngine.splitSentences(text);
      expect(parts, hasLength(1));
      expect(parts.first, 'A short sentence here.');
    });

    test('无标点超长文本按单词边界硬切分', () {
      // 构造超过 300 字符且无标点的文本
      final long = List.generate(60, (i) => 'wordnumber$i').join(' ');
      final parts = SherpaTtsEngine.splitSentences(long);
      expect(parts.length, greaterThan(1));
      // 每段都不超过 300 字符
      for (final p in parts) {
        expect(p.length, lessThanOrEqualTo(300));
      }
      // 拼接还原后应保留所有单词（不丢失、不切开单词）
      expect(parts.join(' ').replaceAll(RegExp(r'\s+'), ' '), long);
    });

    test('hardSplit 单段不超过上限且不切开单词', () {
      final long = List.generate(50, (i) => 'apple$i').join(' ');
      final parts = SherpaTtsEngine.hardSplit(long, 100);
      expect(parts.length, greaterThan(1));
      for (final p in parts) {
        expect(p.length, lessThanOrEqualTo(100));
      }
      expect(parts.join(' ').replaceAll(RegExp(r'\s+'), ' '), long);
    });
  });
}
