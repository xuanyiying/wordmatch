import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordmatch/core/settings/learner_profile.dart';
import 'package:wordmatch/features/feed/data/services/semantic_annotator_service.dart';

void main() {
  setUp(() {
    // 每个 case 独立的干净存储，避免相互污染
    SharedPreferences.setMockInitialValues({});
  });

  group('LearnerProfile.load/save', () {
    test('未设置时返回默认身份（国内开发者）', () async {
      final desc = await LearnerProfile.load();
      expect(desc, LearnerProfile.defaultPreset.desc);
      expect(LearnerProfile.labelFor(desc), '国内开发者');
    });

    test('save 后 load 返回保存的自定义身份', () async {
      await LearnerProfile.save('后端开发工程师');
      expect(await LearnerProfile.load(), '后端开发工程师');
    });

    test('save 去除首尾空白', () async {
      await LearnerProfile.save('  外贸从业者  ');
      expect(await LearnerProfile.load(), '外贸从业者');
    });

    test('存储值为纯空白时回退到默认身份', () async {
      SharedPreferences.setMockInitialValues({'learner_identity_desc': '   '});
      expect(await LearnerProfile.load(), LearnerProfile.defaultPreset.desc);
    });

    test('可切换回预设身份（四六级）', () async {
      await LearnerProfile.save('后端开发工程师');
      await LearnerProfile.save(LearnerProfile.presets[1].desc);
      expect(await LearnerProfile.load(), '备考大学四六级的学生');
    });
  });

  group('LearnerProfile.presets', () {
    test('默认身份是第一个预设且为国内开发者', () {
      expect(LearnerProfile.presets.first, same(LearnerProfile.defaultPreset));
      expect(LearnerProfile.defaultPreset.label, '国内开发者');
    });

    test('预设描述互不重复（labelFor 依赖此前提）', () {
      final descs = LearnerProfile.presets.map((p) => p.desc).toSet();
      expect(descs.length, LearnerProfile.presets.length);
    });
  });

  group('LearnerProfile.labelFor', () {
    test('命中预设返回预设名', () {
      for (final p in LearnerProfile.presets) {
        expect(LearnerProfile.labelFor(p.desc), p.label);
      }
    });

    test('未命中预设返回自定义原文', () {
      expect(LearnerProfile.labelFor('出国读研的学生'), '出国读研的学生');
    });
  });

  group('LearnerProfile.tagOf（FNV-1a 稳定哈希）', () {
    test('固定参考值：算法变更会被测试捕获（跨运行缓存键依赖此稳定性）', () {
      expect(LearnerProfile.tagOf('备考大学四六级的学生'), 'f2448be6');
      expect(LearnerProfile.tagOf('后端开发工程师'), '61b774b3');
    });

    test('同输入同输出，输出为 8 位小写十六进制', () {
      final tag = LearnerProfile.tagOf(LearnerProfile.defaultPreset.desc);
      expect(LearnerProfile.tagOf(LearnerProfile.defaultPreset.desc), tag);
      expect(tag, matches(RegExp(r'^[0-9a-f]{8}$')));
    });

    test('不同身份哈希不同', () {
      final tags = LearnerProfile.presets.map((p) => LearnerProfile.tagOf(p.desc)).toSet();
      expect(tags.length, LearnerProfile.presets.length);
      expect(
        LearnerProfile.tagOf('考研'),
        isNot(LearnerProfile.tagOf('考 研')),
      );
    });
  });

  group('SemanticAnnotatorService 缓存键包含身份', () {
    const sourceId = 'github';
    const articleId = 'flutter/flutter-12345';

    test('同一身份缓存键一致（可命中缓存）', () {
      final a = SemanticAnnotatorService.cacheKeyForTest(
          sourceId, articleId, '后端开发工程师');
      final b = SemanticAnnotatorService.cacheKeyForTest(
          sourceId, articleId, '后端开发工程师');
      expect(a, b);
    });

    test('换身份缓存键变化（旧画像标注自动失效）', () {
      final dev = SemanticAnnotatorService.cacheKeyForTest(
          sourceId, articleId, '后端开发工程师');
      final cet = SemanticAnnotatorService.cacheKeyForTest(
          sourceId, articleId, '备考大学四六级的学生');
      expect(dev, isNot(cet));
    });

    test('键以完整身份标签结尾，且文章 ID 特殊字符被替换', () {
      final key = SemanticAnnotatorService.cacheKeyForTest(
          sourceId, articleId, '后端开发工程师');
      expect(key, endsWith('_61b774b3'));
      expect(key, startsWith('v5_github_flutter_flutter-12345_'));
      expect(key, isNot(contains('/')));
    });
  });
}
