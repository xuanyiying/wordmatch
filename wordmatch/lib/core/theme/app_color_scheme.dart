import 'package:flutter/material.dart';
import 'package:wordmatch/core/constants/app_colors.dart';
import 'skin_theme.dart';

/// 语义化配色 —— 依据当前亮度（浅色/深色）返回一组统一语义的颜色。
///
/// 用法：`context.appColors.card`、`context.appColors.ink` 等。
/// 替代散落在各页面的 `Colors.white` / `AppColors.background` 硬编码，
/// 让卡片/文字/边框在夜间模式自动切换。
class AppColorScheme {
  final Color background;
  final Color card;
  final Color ink; // 主文字
  final Color inkSoft; // 次要文字
  final Color inkFaint; // 弱化文字
  final Color border;
  final Color divider;
  final Color mintBg; // 浅绿填充背景
  final Color mintDeep; // 强调绿（文字/图标）
  final Color mintLight; // 浅薄荷
  final Color amber;
  final Color amberBg;
  final LinearGradient headerGradient;

  const AppColorScheme({
    required this.background,
    required this.card,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.border,
    required this.divider,
    required this.mintBg,
    required this.mintDeep,
    required this.mintLight,
    required this.amber,
    required this.amberBg,
    required this.headerGradient,
  });

  /// 根据皮肤主题生成配色方案。
  ///
  /// [dark] 为 true 时生成夜间版本（深色背景 + 提亮的主色/强调色），
  /// 保证文字与背景对比度；为 false 时直接使用皮肤的浅色定义。
  factory AppColorScheme.ofSkin(AppThemeData skin, {required bool dark}) {
    final bgIsDark = skin.background.computeLuminance() < 0.5;
    final effectiveDark = dark || bgIsDark;
    final background =
        effectiveDark ? skin.backgroundDark : skin.background;
    final card = effectiveDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.06), background)
        : skin.cardBg;

    // 文字/边框按背景亮度选择色阶，避免深色皮肤下文字不可读
    final Color ink =
        effectiveDark ? const Color(0xFFE8F0E4) : AppColors.ink;
    final Color inkSoft =
        effectiveDark ? const Color(0xFFB5C4B5) : AppColors.inkSoft;
    final Color inkFaint =
        effectiveDark ? const Color(0xFF7C8A7C) : AppColors.inkFaint;
    final Color border = effectiveDark
        ? const Color(0xFF2A332B)
        : AppColors.borderDeep;
    final Color divider = effectiveDark
        ? const Color(0xFF243029)
        : AppColors.dividerSoft;

    // 主色/强调色：夜间模式提亮以适配深色背景
    final Color mintDeep = effectiveDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.45), skin.primary)
        : skin.primary;
    final Color mintLight = effectiveDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.62), skin.primary)
        : Color.alphaBlend(
            Colors.white.withValues(alpha: 0.35), skin.primary);
    final Color mintBg = Color.alphaBlend(
        skin.primary.withValues(
            alpha: effectiveDark ? 0.16 : 0.08),
        background);
    final Color amber = effectiveDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.55), skin.accent)
        : skin.accent;
    final Color amberBg = Color.alphaBlend(
        skin.accent.withValues(
            alpha: effectiveDark ? 0.18 : 0.12),
        background);

    return AppColorScheme(
      background: background,
      card: card,
      ink: ink,
      inkSoft: inkSoft,
      inkFaint: inkFaint,
      border: border,
      divider: divider,
      mintBg: mintBg,
      mintDeep: mintDeep,
      mintLight: mintLight,
      amber: amber,
      amberBg: amberBg,
      headerGradient: skin.headerGradient,
    );
  }

  /// 浅色（复用现有 AppColors 常量，保持视觉一致）
  static const light = AppColorScheme(
    background: AppColors.background,
    card: Colors.white,
    ink: AppColors.ink,
    inkSoft: AppColors.inkSoft,
    inkFaint: AppColors.inkFaint,
    border: AppColors.borderDeep,
    divider: AppColors.dividerSoft,
    mintBg: AppColors.mintBg,
    mintDeep: AppColors.mintDeep,
    mintLight: AppColors.mintLight,
    amber: AppColors.amber,
    amberBg: AppColors.amberBg,
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.forestStart, AppColors.forestMid, AppColors.forestEnd],
    ),
  );

  /// 深色（森林绿夜间版）
  static const dark = AppColorScheme(
    background: Color(0xFF121814),
    card: Color(0xFF1C2620),
    ink: Color(0xFFE8F0E4),
    inkSoft: Color(0xFFB5C4B5),
    inkFaint: Color(0xFF7C8A7C),
    border: Color(0xFF2A332B),
    divider: Color(0xFF243029),
    mintBg: Color(0xFF1F2E24),
    mintDeep: Color(0xFF7DD47D),
    mintLight: Color(0xFF5AB838),
    amber: Color(0xFFE8C766),
    amberBg: Color(0xFF2E2818),
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1F5C1F), Color(0xFF2F6B2F), Color(0xFF3A7A2A)],
    ),
  );
}

/// 主题中的语义配色承载（ThemeExtension）。
///
/// [AppTheme.light]/[AppTheme.dark] 构建时按当前皮肤生成一个
/// [AppColorScheme] 放入 extensions，页面通过 `context.appColors`
/// 读取；皮肤切换 → 主题重建 → 所有依赖 Theme 的页面自动拿到新配色。
@immutable
class AppColorSchemeTheme extends ThemeExtension<AppColorSchemeTheme> {
  final AppColorScheme scheme;

  const AppColorSchemeTheme(this.scheme);

  @override
  AppColorSchemeTheme copyWith({AppColorScheme? scheme}) =>
      AppColorSchemeTheme(scheme ?? this.scheme);

  @override
  AppColorSchemeTheme lerp(AppColorSchemeTheme? other, double t) {
    if (other == null) return this;
    // 皮肤切换不做颜色插值，直接切换目标方案，避免动画中出现异常色值
    return AppColorSchemeTheme(t < 0.5 ? scheme : other.scheme);
  }
}

/// 语义配色快捷访问：优先读取主题内置的皮肤配色，
/// 未配置时回退到浅色/深色默认方案。
extension AppColorSchemeX on BuildContext {
  AppColorScheme get appColors {
    final ext = Theme.of(this).extension<AppColorSchemeTheme>();
    if (ext != null) return ext.scheme;
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? AppColorScheme.dark : AppColorScheme.light;
  }
}
