import 'package:flutter/material.dart';
import 'app_color_scheme.dart';
import 'skin_theme.dart';

/// 应用主题配置 — Wise 风格：明亮绿色点缀，友好而清晰。
///
/// [light]/[dark] 均接受当前皮肤 [AppThemeData]，皮肤决定主色/强调色/
/// 背景/卡片色，并随主题注入 [AppColorSchemeTheme]，让 `context.appColors`
/// 全局跟随皮肤与夜间模式。
class AppTheme {
  AppTheme._();

  static ThemeData light([AppThemeData? skin]) {
    final s = skin ?? AppThemes.academic;
    final scheme = AppColorScheme.ofSkin(s, dark: false);
    final bgIsDark = s.background.computeLuminance() < 0.5;
    return ThemeData(
      useMaterial3: true,
      // 深色皮肤（太空/赛博朋克）即使在浅色模式下也应使用深色文字/控件
      brightness: bgIsDark ? Brightness.dark : Brightness.light,
      colorSchemeSeed: s.primary,
      fontFamily: null, // 使用系统默认字体，中文自动走 PingFang SC
      scaffoldBackgroundColor: scheme.background,
      extensions: [AppColorSchemeTheme(scheme)],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.card,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: scheme.ink),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: scheme.card,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: s.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: scheme.ink,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: scheme.ink,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: scheme.ink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: scheme.ink,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: scheme.inkSoft,
          fontSize: 14,
        ),
      ),
    );
  }

  /// 深色主题 — 森林绿夜间版
  /// 保持品牌色系，背景/卡片/文字均换为深色可读版本。
  static ThemeData dark([AppThemeData? skin]) {
    final s = skin ?? AppThemes.academic;
    final scheme = AppColorScheme.ofSkin(s, dark: true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: s.primary,
      fontFamily: null,
      scaffoldBackgroundColor: scheme.background,
      extensions: [AppColorSchemeTheme(scheme)],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.card,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: scheme.ink),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: scheme.card,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.mintDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: scheme.ink,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: scheme.ink,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: scheme.ink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: scheme.ink,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: scheme.inkSoft,
          fontSize: 14,
        ),
      ),
    );
  }
}
