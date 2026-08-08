import 'package:flutter_test/flutter_test.dart';
import 'package:wordmatch/features/wordbook/data/services/custom_wordbook_importer.dart';

void main() {
  group('CustomWordbookImporter', () {
    test('JSON 解析成功：基本字段', () {
      const content = '''
{
  "name": "雅思核心",
  "words": [
    {"word": "abandon", "phonetic": "əˈbændən", "definition": ["放弃", "抛弃"]},
    {"word": "benefit", "definition": ["利益"]},
    {"word": "candidate", "definition": ["候选人"]},
    {"word": "diligent", "definition": ["勤奋的"]},
    {"word": "eager", "definition": ["渴望的"]}
  ]
}
''';
      final result = CustomWordbookImporter.parse(content, 'json');
      expect(result.isSuccess, true);
      expect(result.name, '雅思核心');
      expect(result.words.length, 5);
      expect(result.words.first.word, 'abandon');
      expect(result.words.first.phonetic, 'əˈbændən');
      expect(result.words.first.definition, ['放弃', '抛弃']);
    });

    test('JSON 解析失败：缺少 name', () {
      const content = '''
{
  "words": [
    {"word": "a", "definition": ["1"]},
    {"word": "b", "definition": ["2"]},
    {"word": "c", "definition": ["3"]},
    {"word": "d", "definition": ["4"]}
  ]
}
''';
      final result = CustomWordbookImporter.parse(content, 'json');
      expect(result.isSuccess, false);
      expect(result.error, contains('name'));
    });

    test('JSON 解析失败：词条数 < 4', () {
      const content = '''
{
  "name": "too few",
  "words": [
    {"word": "a", "definition": ["1"]},
    {"word": "b", "definition": ["2"]}
  ]
}
''';
      final result = CustomWordbookImporter.parse(content, 'json');
      expect(result.isSuccess, false);
      expect(result.error, contains('不足'));
    });

    test('JSON 解析失败：行级错误带行号', () {
      const content = '''
{
  "name": "x",
  "words": [
    {"word": "good", "definition": ["好"]},
    {"word": "", "definition": ["坏"]},
    {"word": "c", "definition": ["c"]},
    {"word": "d", "definition": ["d"]}
  ]
}
''';
      final result = CustomWordbookImporter.parse(content, 'json');
      expect(result.isSuccess, false);
      expect(result.error, contains('第 2'));
    });

    test('JSON 解析：去重', () {
      const content = '''
{
  "name": "dup",
  "words": [
    {"word": "test", "definition": ["1"]},
    {"word": "test", "definition": ["2"]},
    {"word": "test", "definition": ["3"]},
    {"word": "other", "definition": ["4"]},
    {"word": "third", "definition": ["5"]},
    {"word": "fourth", "definition": ["6"]}
  ]
}
''';
      final result = CustomWordbookImporter.parse(content, 'json');
      expect(result.isSuccess, true);
      expect(result.words.length, 4);
    });

    test('CSV 解析成功', () {
      const content = '''word,phonetic,definition
abandon,əˈbændən,放弃;抛弃
benefit,ˈbenɪfɪt,利益
candidate,ˈkændɪdeɪt,候选人
diligent,ˈdɪlɪdʒənt,勤奋的
eager,ˈiːɡər,渴望的
''';
      final result = CustomWordbookImporter.parse(content, 'csv');
      expect(result.isSuccess, true);
      expect(result.name, '导入词库');
      expect(result.words.length, 5);
      expect(result.words.first.word, 'abandon');
      expect(result.words.first.definition, ['放弃', '抛弃']);
    });

    test('CSV 解析成功：传入词库名', () {
      const content = '''word,phonetic,definition
abandon,əˈbændən,放弃;抛弃
benefit,ˈbenɪfɪt,利益
candidate,ˈkændɪdeɪt,候选人
diligent,ˈdɪlɪdʒənt,勤奋的
eager,ˈiːɡər,渴望的
''';
      final result = CustomWordbookImporter.parse(content, 'csv', name: '我的词库');
      expect(result.isSuccess, true);
      expect(result.name, '我的词库');
    });

    test('CSV 解析失败：缺表头', () {
      const content = 'a,b,c\n1,2,3\n4,5,6\n7,8,9\n10,11,12';
      final result = CustomWordbookImporter.parse(content, 'csv');
      expect(result.isSuccess, false);
    });

    test('detectFormat 正确', () {
      expect(CustomWordbookImporter.detectFormat('a.json'), 'json');
      expect(CustomWordbookImporter.detectFormat('a.JSON'), 'json');
      expect(CustomWordbookImporter.detectFormat('a.csv'), 'csv');
      expect(CustomWordbookImporter.detectFormat('a.txt'), isNull);
    });
  });
}
