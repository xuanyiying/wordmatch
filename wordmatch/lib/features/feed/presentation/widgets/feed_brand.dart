import 'package:flutter/material.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';

/// 各资讯源的品牌视觉常量（官方 App 配色）。
///
/// 仅内容元素（链接/色点/徽章）使用固定品牌色；
/// 卡片容器一律走 [AppColorScheme] 的 card/border，保证夜间模式可用。
abstract final class FeedBrand {
  /// Hacker News 官方橙
  static const Color hnOrange = Color(0xFFFF6600);

  /// Product Hunt 品牌橙红
  static const Color phOrange = Color(0xFFDA552F);

  /// dev.to 品牌蓝
  static const Color devtoBlue = Color(0xFF3B49DF);

  /// GitHub 链接蓝（浅色 / 深色两档，与官网一致）
  static const Color githubLinkLight = Color(0xFF0969DA);
  static const Color githubLinkDark = Color(0xFF4493F8);

  static Color githubLink(Brightness brightness) =>
      brightness == Brightness.dark ? githubLinkDark : githubLinkLight;
}

/// GitHub Linguist 官方语言色（常用语言子集），未知语言返回 null。
Color? languageColor(String language) => switch (language.trim()) {
      'JavaScript' => const Color(0xFFF1E05A),
      'Python' => const Color(0xFF3572A5),
      'Dart' => const Color(0xFF00B4AB),
      'TypeScript' => const Color(0xFF3178C6),
      'Go' => const Color(0xFF00ADD8),
      'Rust' => const Color(0xFFDEA584),
      'Java' => const Color(0xFFB07219),
      'Swift' => const Color(0xFFF05138),
      'Kotlin' => const Color(0xFFA97BFF),
      'Ruby' => const Color(0xFF701516),
      'Shell' => const Color(0xFF89E051),
      'C++' => const Color(0xFFF34B7D),
      'C' => const Color(0xFF555555),
      'C#' => const Color(0xFF178600),
      'HTML' => const Color(0xFFE34C26),
      'CSS' => const Color(0xFF563D7C),
      'Vue' => const Color(0xFF41B883),
      'PHP' => const Color(0xFF4F5D95),
      'Zig' => const Color(0xFFEC915C),
      'Jupyter Notebook' || 'Jupyter' => const Color(0xFFDA5B0B),
      'MDX' => const Color(0xFFFCB32C),
      'Makefile' || 'CMake' => const Color(0xFF427819),
      _ => null,
    };

/// 语言色点 + 语言名（GitHub 仓库 meta 行样式）。
class LanguageDot extends StatelessWidget {
  final String language;
  final Color fallback;
  final TextStyle? textStyle;

  const LanguageDot(
    this.language, {
    super.key,
    Color? fallback,
    this.textStyle,
  }) : fallback = fallback ?? const Color(0xFF8B949E);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: languageColor(language) ?? fallback,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(language, style: textStyle),
      ],
    );
  }
}

/// 资讯卡片公共容器：card 背景 + border + 圆角 14 + InkWell。
class FeedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const FeedCard({super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}
