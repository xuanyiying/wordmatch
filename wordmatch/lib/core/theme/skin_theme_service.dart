import 'package:shared_preferences/shared_preferences.dart';
import 'skin_theme.dart';

class ThemeService {
  ThemeService._();
  static const _kKey = 'app_theme_key';

  static Future<AppThemeKey> getCurrent() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_kKey);
      return switch (s) {
        'forest' => AppThemeKey.forest,
        'space' => AppThemeKey.space,
        'cyberpunk' => AppThemeKey.cyberpunk,
        _ => AppThemeKey.academic,
      };
    } catch (_) {
      return AppThemeKey.academic;
    }
  }

  static Future<void> setCurrent(AppThemeKey k) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kKey, k.name);
  }
}
