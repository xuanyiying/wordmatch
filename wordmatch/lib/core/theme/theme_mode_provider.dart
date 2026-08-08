import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式（夜间模式）档位 —— 跟随系统 / 浅色 / 深色。
///
/// 结构对齐 [FontScaleNotifier] / [CardThemeNotifier]，持久化到
/// SharedPreferences，供 `MaterialApp.themeMode` 消费。
enum AppThemeMode {
  system('跟随系统', ThemeMode.system),
  light('浅色', ThemeMode.light),
  dark('深色', ThemeMode.dark);

  final String label;
  final ThemeMode themeMode;
  const AppThemeMode(this.label, this.themeMode);
}

/// 主题模式 Notifier —— 持久化到 SharedPreferences。
class ThemeModeNotifier extends AsyncNotifier<AppThemeMode> {
  static const String _prefsKey = 'app_theme_mode';

  @override
  Future<AppThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null) {
      return AppThemeMode.values.firstWhere(
        (e) => e.name == stored,
        orElse: () => AppThemeMode.system,
      );
    }
    return AppThemeMode.system;
  }

  /// 切换档位并持久化。
  Future<void> set(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
    state = AsyncData(mode);
  }
}

// 必须在 Notifier 类定义之后才能引用
final themeModeControllerProvider =
    AsyncNotifierProvider<ThemeModeNotifier, AppThemeMode>(
  ThemeModeNotifier.new,
);

/// 同步获取当前档位（带默认值回退），供 MaterialApp 直接 watch。
final themeModeValueProvider = Provider<ThemeMode>((ref) {
  final asyncValue = ref.watch(themeModeControllerProvider);
  return asyncValue.value?.themeMode ?? ThemeMode.system;
});
