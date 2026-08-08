import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'skin_theme.dart';
import 'skin_theme_service.dart';

final themeProvider = FutureProvider<AppThemeKey>((ref) async => ThemeService.getCurrent());

/// 当前皮肤数据（含全部配色），供 MaterialApp 构建主题使用。
/// 皮肤切换时 themeProvider 失效 → 本 Provider 重建 → 全 App 重新主题化。
final skinThemeDataProvider = Provider<AppThemeData>((ref) {
  final key = ref.watch(themeProvider).value ?? AppThemeKey.academic;
  return AppThemes.of(key);
});
