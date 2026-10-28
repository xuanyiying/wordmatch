import 'package:shared_preferences/shared_preferences.dart';

/// 学习者身份预设（label 给 UI 展示，desc 送入 AI 提示词）
class LearnerProfilePreset {
  final String label;
  final String desc;
  const LearnerProfilePreset(this.label, this.desc);
}

/// 用户身份设置：决定 AI 标注/讲解面向的学习者画像。
/// 主目标用户为国内开发者，默认「国内开发者」，支持自定义描述。
class LearnerProfile {
  LearnerProfile._();

  static const _kDesc = 'learner_identity_desc';

  static const LearnerProfilePreset defaultPreset =
      LearnerProfilePreset('国内开发者', '国内开发者，常读英文技术文档、开源项目与技术博客');

  static const List<LearnerProfilePreset> presets = [
    defaultPreset,
    LearnerProfilePreset('大学生 · 四六级', '备考大学四六级的学生'),
    LearnerProfilePreset('考研', '备考考研英语的学生'),
    LearnerProfilePreset('雅思/托福', '备考雅思或托福的出国学习者'),
    LearnerProfilePreset('职场英语', '工作需要用英语的职场人'),
  ];

  /// 读取当前身份描述（未设置时返回默认：国内开发者）
  static Future<String> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_kDesc);
      if (v != null && v.trim().isNotEmpty) return v.trim();
      return defaultPreset.desc;
    } catch (_) {
      return defaultPreset.desc;
    }
  }

  /// 保存身份描述（预设的 desc 或用户自定义文本）
  static Future<void> save(String desc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDesc, desc.trim());
  }

  /// 描述 → 展示名（命中预设返回预设名，否则原文即自定义内容）
  static String labelFor(String desc) {
    for (final p in presets) {
      if (p.desc == desc) return p.label;
    }
    return desc;
  }

  /// 身份 → 稳定短标签（FNV-1a），用于标注缓存键：
  /// 换身份后自动失效旧缓存，避免拿到按旧画像标注的结果。
  static String tagOf(String desc) {
    var h = 0x811c9dc5;
    for (final cu in desc.codeUnits) {
      h ^= cu;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }
}
