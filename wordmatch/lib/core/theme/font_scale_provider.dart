import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 字体大小档位 —— 全局统一缩放所有 `Text` 的字号。
///
/// 实现方式：在 [main.dart] 的 `MaterialApp.builder` 里用
/// `MediaQuery.copyWith(textScaler: TextScaler.linear(scale))` 覆盖系统
/// 文本缩放系数。这样所有页面里硬编码的 `fontSize` 都会按同一比例缩放，
/// 既保证「字体大小一致」，又支持用户全局调节，无需逐个改写每一处字号。
enum FontScaleLevel {
  small('小', 0.85, '一屏看更多内容'),
  standard('标准', 1.0, '默认舒适大小'),
  large('大', 1.15, '字号放大，阅读更轻松'),
  extraLarge('特大', 1.3, '最大字号，视力友好');

  final String label;
  final double scale;
  final String desc;
  const FontScaleLevel(this.label, this.scale, this.desc);
}

/// 字体档位 Notifier —— 持久化到 SharedPreferences。
/// 与 [CardThemeNotifier] 同构，便于维护一致性。
class FontScaleNotifier extends AsyncNotifier<FontScaleLevel> {
  static const String _prefsKey = 'font_scale_level';

  @override
  Future<FontScaleLevel> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null) {
      return FontScaleLevel.values.firstWhere(
        (e) => e.name == stored,
        orElse: () => FontScaleLevel.standard,
      );
    }
    return FontScaleLevel.standard;
  }

  /// 切换档位并持久化。
  Future<void> set(FontScaleLevel level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, level.name);
    state = AsyncData(level);
  }
}

// 必须在 Notifier 类定义之后才能引用
final fontScaleControllerProvider =
    AsyncNotifierProvider<FontScaleNotifier, FontScaleLevel>(
  FontScaleNotifier.new,
);

/// 同步获取当前档位（带默认值回退），供设置页等非 async 场景直接 watch。
final fontScaleLevelProvider = Provider<FontScaleLevel>((ref) {
  final asyncValue = ref.watch(fontScaleControllerProvider);
  return asyncValue.value ?? FontScaleLevel.standard;
});

/// 当前字体缩放比例 —— 供 `MaterialApp.builder` 注入 `MediaQuery.textScaler`。
final fontScaleProvider = Provider<double>((ref) {
  final level = ref.watch(fontScaleLevelProvider);
  return level.scale;
});
