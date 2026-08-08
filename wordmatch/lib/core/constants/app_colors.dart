import 'package:flutter/material.dart';

/// 应用颜色常量 — Wise 风格配色：明亮绿色点缀，友好而清晰
class AppColors {
  AppColors._();

  /// 主色调：Wise 标志性亮绿
  static const int primaryGreenValue = 0xFF9FE870;
  static const MaterialColor primaryGreen = MaterialColor(
    primaryGreenValue,
    <int, Color>{
      50: Color(0xFFF2FFE8),
      100: Color(0xFFD4FFC0),
      200: Color(0xFFB8FF98),
      300: Color(0xFFA0F070),
      400: Color(0xFF9FE870),
      500: Color(primaryGreenValue),
      600: Color(0xFF7CD050),
      700: Color(0xFF5AB838),
      800: Color(0xFF3A9C22),
      900: Color(0xFF163300),
    },
  );

  /// 深绿（文字/标题用）
  static const Color primaryGreenDark = Color(0xFF163300);

  /// 强调色：暖琥珀
  static const Color accentOrange = Color(0xFFFFB800);

  /// 卡牌背景
  static const Color cardBackground = Color(0xFFF7F9F7);

  /// 卡牌阴影
  static const Color cardShadow = Color(0xFFD0D8CE);

  /// 成功绿
  static const Color success = Color(0xFF00C261);

  /// 失败红
  static const Color error = Color(0xFFDE350B);

  /// 文字主色（深绿，保持友好不刺眼）
  static const Color textPrimary = Color(0xFF163300);

  /// 文字次色
  static const Color textSecondary = Color(0xFF6B7C6E);

  /// 背景色（略带暖调的灰白）
  static const Color background = Color(0xFFF5F7F5);

  /// 次级背景（白色卡片浮层）
  static const Color surface = Color(0xFFFFFFFF);

  /// 边框/分隔线
  static const Color border = Color(0xFFE2E8E0);

  /// 禁用/占位色
  static const Color disabled = Color(0xFFB0B8AE);

  // ==================== 深森林绿配色（年轻化 v4） ====================
  // 主文字（墨绿黑，比 primaryGreenDark 更深沉）
  static const Color ink = Color(0xFF0F2E0F);
  // 次要文字（深苔绿）
  static const Color inkSoft = Color(0xFF4A6A4A);
  // 弱化文字
  static const Color inkFaint = Color(0xFF9DB09D);

  // 深森林绿渐变三色（Header / 整合卡 / 主按钮）
  static const Color forestStart = Color(0xFF1F5C1F);
  static const Color forestMid = Color(0xFF2F6B2F);
  static const Color forestEnd = Color(0xFF3A7A2A);

  // 强调绿（比 primaryGreen 深，用于文字/图标强调）
  static const Color mintDeep = Color(0xFF3DA860);
  // 浅薄荷（高亮填充）
  static const Color mintLight = Color(0xFF7DD47D);
  // 浅绿背景（卡片底色）
  static const Color mintBg = Color(0xFFE8F4E3);

  // 暖琥珀（降饱和版，用于复习/打卡）
  static const Color amber = Color(0xFFD4900A);
  static const Color amberSoft = Color(0xFFE8C766);
  static const Color amberBg = Color(0xFFFBE9B8);

  // 辅助色（词库 tag / 主题）
  static const Color coral = Color(0xFFFF8E72);
  static const Color lilac = Color(0xFFB8A4E8);
  static const Color sky = Color(0xFF7EC8E3);

  // 深色版边框/分割线
  static const Color borderDeep = Color(0xFFD8DFD8);
  static const Color dividerSoft = Color(0xFFE8ECE8);
}
