import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordmatch/core/theme/card_theme.dart';

/// 卡片主题 Notifier
class CardThemeNotifier extends AsyncNotifier<CardThemeType> {
  static const String _prefsKey = 'card_theme';

  @override
  Future<CardThemeType> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null) {
      return CardThemeType.values.firstWhere(
        (e) => e.name == stored,
        orElse: () => CardThemeType.academic,
      );
    }
    return CardThemeType.academic;
  }

  /// 切换主题并持久化
  Future<void> set(CardThemeType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, type.name);
    state = AsyncData(type);
  }
}

// 必须在 Notifier 类定义之后才能引用
final cardThemeControllerProvider =
    AsyncNotifierProvider<CardThemeNotifier, CardThemeType>(
  CardThemeNotifier.new,
);

/// 当前主题 type provider（仅返回枚举值，方便 GameScreen 等 ConsumerWidget 直接 watch）
final cardThemeTypeProvider = Provider<CardThemeType>((ref) {
  final asyncValue = ref.watch(cardThemeControllerProvider);
  return asyncValue.value ?? CardThemeType.academic;
});
