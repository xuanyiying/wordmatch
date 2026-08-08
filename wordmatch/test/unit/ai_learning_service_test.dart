import 'package:flutter_test/flutter_test.dart';
import 'package:wordmatch/features/ai/data/services/ai_learning_service.dart';

void main() {
  group('AiLearningService', () {
    group('parseDialogue', () {
      test('解析完整对话', () {
        final result = AiLearningService.parseDialogue({
          'scenario': '在咖啡馆讨论计划',
          'lines': [
            {'speaker': 'A', 'en': 'What do you plan to do this weekend?',
             'zh': '你这个周末打算做什么？'},
            {'speaker': 'B', 'en': 'I plan to abandon my old hobby.',
             'zh': '我打算放弃我的旧爱好。'},
          ],
        });

        expect(result.scenario, '在咖啡馆讨论计划');
        expect(result.lines.length, 2);
        expect(result.lines.first.speaker, 'A');
        expect(result.lines.first.en, 'What do you plan to do this weekend?');
        expect(result.lines.first.zh, '你这个周末打算做什么？');
        expect(result.isEmpty, false);
      });

      test('空数据返回空结果', () {
        final result = AiLearningService.parseDialogue({});

        expect(result.scenario, '');
        expect(result.lines, isEmpty);
        expect(result.isEmpty, true);
      });

      test('过滤无效台词条目', () {
        final result = AiLearningService.parseDialogue({
          'scenario': '讨论计划',
          'lines': [
            {'speaker': 'A', 'en': 'Hello.', 'zh': '你好。'},
            {'speaker': '', 'en': 'Missing speaker.', 'zh': '缺少说话人。'},
            {'speaker': 'B', 'en': '', 'zh': '缺少英文。'},
            {'speaker': 'B', 'en': 'Goodbye.', 'zh': '再见。'},
            {'speaker': 'C', 'en': 'See you.', 'zh': ''},
          ],
        });

        expect(result.lines.length, 2);
        expect(result.lines.first.en, 'Hello.');
        expect(result.lines.last.en, 'Goodbye.');
      });
    });

    group('DialogueLine', () {
      test('正确保存字段', () {
        const line = DialogueLine(
          speaker: 'A',
          en: 'How are you?',
          zh: '你好吗？',
        );

        expect(line.speaker, 'A');
        expect(line.en, 'How are you?');
        expect(line.zh, '你好吗？');
      });
    });

    group('DialogueResult', () {
      test('空结果判断', () {
        const empty = DialogueResult();
        expect(empty.isEmpty, true);

        const withScenario = DialogueResult(scenario: '情景');
        expect(withScenario.isEmpty, false);

        const withLines = DialogueResult(lines: [
          DialogueLine(speaker: 'A', en: 'Hi.', zh: '嗨。'),
        ]);
        expect(withLines.isEmpty, false);
      });
    });
  });
}
