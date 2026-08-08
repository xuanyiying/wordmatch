import 'package:flutter/material.dart';

enum AppThemeKey { academic, forest, space, cyberpunk }

extension AppThemeKeyX on AppThemeKey {
  String get displayName => switch(this){
    AppThemeKey.academic => '默认·学术绿',
    AppThemeKey.forest => '🌲 森林',
    AppThemeKey.space => '🚀 太空',
    AppThemeKey.cyberpunk => '🌆 赛博朋克',
  };
  bool get isProOnly => this != AppThemeKey.academic;
}

class AppThemeData {
  final AppThemeKey key;
  final Color primary;
  final Color primaryDark;
  final Color background;
  final Color backgroundDark;
  final Color cardBg;
  final Color accent;
  final LinearGradient headerGradient;

  const AppThemeData({
    required this.key,
    required this.primary,
    required this.primaryDark,
    required this.background,
    required this.backgroundDark,
    required this.cardBg,
    required this.accent,
    required this.headerGradient,
  });
}

class AppThemes {
  static AppThemeData get academic => AppThemeData(
    key: AppThemeKey.academic,
    primary: Color(0xFF4E7B35),
    primaryDark: Color(0xFF3A6C28),
    background: Color(0xFFF6F8F2),
    backgroundDark: Color(0xFF121814),
    cardBg: Colors.white,
    accent: Color(0xFFD97706),
    headerGradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4E7B35), Color(0xFF3A6C28)]),
  );
  static AppThemeData get forest => AppThemeData(
    key: AppThemeKey.forest,
    primary: Color(0xFF059669),
    primaryDark: Color(0xFF047857),
    background: Color(0xFFECFDF5),
    backgroundDark: Color(0xFF0C1F16),
    cardBg: Color(0xFFFFFFFF),
    accent: Color(0xFFF59E0B),
    headerGradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF10B981), Color(0xFF047857)]),
  );
  static AppThemeData get space => AppThemeData(
    key: AppThemeKey.space,
    primary: Color(0xFF6366F1),
    primaryDark: Color(0xFF4338CA),
    background: Color(0xFF0F172A),
    backgroundDark: Color(0xFF0A0F1E),
    cardBg: Color(0xFF1E293B),
    accent: Color(0xFFF472B6),
    headerGradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6366F1), Color(0xFF1E293B)]),
  );
  static AppThemeData get cyberpunk => AppThemeData(
    key: AppThemeKey.cyberpunk,
    primary: Color(0xFFEC4899),
    primaryDark: Color(0xFFBE185D),
    background: Color(0xFF09090B),
    backgroundDark: Color(0xFF060607),
    cardBg: Color(0xFF18181B),
    accent: Color(0xFF22D3EE),
    headerGradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEC4899), Color(0xFF7C3AED)]),
  );

  static AppThemeData of(AppThemeKey k) => switch(k){
    AppThemeKey.academic => academic,
    AppThemeKey.forest => forest,
    AppThemeKey.space => space,
    AppThemeKey.cyberpunk => cyberpunk,
  };
  static List<AppThemeData> get all => [academic, forest, space, cyberpunk];
}
