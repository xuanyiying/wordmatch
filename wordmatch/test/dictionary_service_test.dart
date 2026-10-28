import 'package:flutter_test/flutter_test.dart';
import 'package:wordmatch/features/feed/data/services/dictionary_service.dart';

void main() {
  group('DictionaryService.normalize', () {
    test('短语保留空格并折叠多余空白', () {
      expect(DictionaryService.normalize('look forward to'), 'look forward to');
      expect(DictionaryService.normalize('  figure   out  '), 'figure out');
    });

    test('去标点、转小写，保留连字符与撇号', () {
      expect(DictionaryService.normalize('Tests,'), 'tests');
      expect(DictionaryService.normalize('well-known'), 'well-known');
      expect(DictionaryService.normalize("don't!"), "don't");
    });

    test('非字母内容清空', () {
      expect(DictionaryService.normalize('123'), '');
      expect(DictionaryService.normalize('...'), '');
    });
  });
}
