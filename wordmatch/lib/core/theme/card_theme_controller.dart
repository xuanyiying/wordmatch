import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordmatch/core/theme/card_theme.dart';

/// 卡片主题全局控制器
class CardThemeController {
  static const String _prefsKey = 'card_theme';

  CardThemeType _current = CardThemeType.academic;
  CardThemeType get current => _current;

  /// 加载持久化值
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null) {
      _current = CardThemeType.values.firstWhere(
        (e) => e.name == stored,
        orElse: () => CardThemeType.academic,
      );
    }
  }

  /// 切换主题并持久化
  Future<void> set(CardThemeType type) async {
    if (type == _current) return;
    _current = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, type.name);
  }
}
