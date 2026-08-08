import 'package:flutter/material.dart';

/// 卡片主题枚举
enum CardThemeType {
  /// 学术经典（英语词汇默认）
  academic,

  /// 森系自然
  forest,

  /// 太空星际
  space,
}

/// 材质纹理类型
enum CardTextureType {
  /// 学术 — 纸页质感：细微纤维/噪点
  paper,

  /// 森系 — 木纹质感：温暖水平纹理
  wood,

  /// 太空 — 玻璃质感：霜化微光
  glass,
}

/// 卡片材质数据：定义纹理、阴影、高光属性
class CardMaterial {
  final CardTextureType textureType;
  final Color noiseColor; // subtle noise overlay color
  final double noiseOpacity; // 0.0-0.06
  final Color shimmerColor; // highlight sweep color
  final double shadowDepth; // shadow blur radius offset
  final double shadowOpacity; // shadow intensity
  final double borderGlowWidth; // selected glow spread

  const CardMaterial({
    required this.textureType,
    required this.noiseColor,
    required this.noiseOpacity,
    required this.shimmerColor,
    required this.shadowDepth,
    required this.shadowOpacity,
    required this.borderGlowWidth,
  });
}

/// 闲置微动画类型
enum IdleAnimationType {
  /// 学术 — 纸页微颤：Y 轴微缩振荡 (0.98↔1.0)
  paperFlutter,

  /// 森系 — 有机呼吸：缩放+微旋转 (0.97↔1.0, ±0.5°)
  organicBreathe,

  /// 太空 — 零重力漂浮：Y 轴微移+透明度闪烁 (±1px, 0.95↔1.0)
  floatShimmer,
}

/// 选中态动画类型（v2）
enum SelectedAnimationType {
  /// 持续呼吸：scale 1.10↔1.13 + 缎带/徽章亮度脉动（1.6s 循环，Option D）
  breathe,
}

/// 闪光元素规格
class SparkleSpec {
  final double topPercent; // 0-100
  final double leftPercent; // 0-100
  final double fontSize;
  final String char;
  final double opacity; // 0-1

  const SparkleSpec({
    required this.topPercent,
    required this.leftPercent,
    required this.fontSize,
    required this.char,
    this.opacity = 1.0,
  });
}

/// 背景图标规格（11% 透明）
class BgIconSpec {
  final double topPercent;
  final double leftPercent;
  final double fontSize;
  final String char;

  const BgIconSpec({
    required this.topPercent,
    required this.leftPercent,
    required this.fontSize,
    required this.char,
  });
}

/// 卡片装饰数据：缎带、角标、图标群、光斑、闪光
class CardDecorations {
  /// 缎带文字（如 "★ CET-4" / "v. 释义" / "🍃 n."）
  final String ribbonText;

  /// 4 角 emoji
  final List<String> cornerEmojis;

  /// 背景散落图标群（11% 透明）
  final List<BgIconSpec> bgIcons;

  /// 3 色径向光斑 [左上白, 右下主题色, 中央 accent]
  final List<Color> bgBlobColors;

  /// 闪光 2-3 颗
  final List<SparkleSpec> sparkles;

  /// 徽章文字 "EN" / "中"
  final String badgeText;

  /// 内部装饰框颜色（虚线+双框）
  final Color frameColor;

  /// 缎带颜色
  final Color ribbonColor;

  /// 徽章颜色
  final Color badgeColor;

  /// 闪光颜色
  final Color sparkleColor;

  /// 匹配印章颜色（用于 MatchedSeal）
  final Color sealColor;

  const CardDecorations({
    required this.ribbonText,
    required this.cornerEmojis,
    required this.bgIcons,
    required this.bgBlobColors,
    required this.sparkles,
    required this.badgeText,
    required this.frameColor,
    required this.ribbonColor,
    required this.badgeColor,
    required this.sparkleColor,
    required this.sealColor,
  });
}

/// 主题的明/暗变体数据
class CardThemeVariant {
  /// 未选中态：typeA 卡
  final CardStateColors typeAIdle;

  /// 未选中态：typeB 卡
  final CardStateColors typeBIdle;

  /// 已选中态：typeA 卡
  final CardStateColors typeASelected;

  /// 已选中态：typeB 卡
  final CardStateColors typeBSelected;

  /// 已匹配态
  final CardStateColors matched;

  /// 装饰层叠 Widget Builder（用于在卡片内绘制印章/星点/HUD 文本等）
  final Widget Function(BuildContext, CardFaceType, CardVisualState)? decorator;

  /// 游戏屏幕暗色背景渐变
  final LinearGradient gameBgGradient;

  /// 游戏屏幕主题色辉光
  final Color gameBgGlow;

  /// 卡片材质
  final CardMaterial material;

  /// 闲置微动画类型
  final IdleAnimationType idleAnimation;

  /// 匹配爆炸粒子颜色
  final List<Color> burstColors;

  /// 背景浮动元素颜色
  final Color ambientElementColor;

  const CardThemeVariant({
    required this.typeAIdle,
    required this.typeBIdle,
    required this.typeASelected,
    required this.typeBSelected,
    required this.matched,
    this.decorator,
    required this.gameBgGradient,
    required this.gameBgGlow,
    required this.material,
    required this.idleAnimation,
    required this.burstColors,
    required this.ambientElementColor,
  });
}

/// 三态视觉数据
class CardStateColors {
  final Color background;
  final Color border;
  final double borderWidth;
  final Color text;
  final List<BoxShadow>? boxShadows;
  final FontWeight fontWeight;
  final String? fontFamily;
  final bool useLineThrough;
  final double opacity;
  final LinearGradient? gradient;
  final Color? innerShadowColor;
  final Shadow? textShadow;
  final Color? badgeColor;
  final Color? badgeText;

  /// v2 装饰数据（可选，向后兼容）
  final CardDecorations? decorations;

  const CardStateColors({
    required this.background,
    required this.border,
    this.borderWidth = 1.5,
    required this.text,
    this.boxShadows,
    this.fontWeight = FontWeight.w500,
    this.fontFamily,
    this.useLineThrough = false,
    this.opacity = 1.0,
    this.gradient,
    this.innerShadowColor,
    this.textShadow,
    this.badgeColor,
    this.badgeText,
    this.decorations,
  });
}

/// 卡片面类型（typeA/typeB）— 区别于 game_card.dart 里的 CardType，避免命名冲突
enum CardFaceType { typeA, typeB }

/// 卡片视觉状态
enum CardVisualState { idle, selected, matched }

/// 卡片主题元数据 + 三态颜色体系
class CardVisualTheme {
  final CardThemeType type;
  final String label;
  final String description;
  final String tag;
  final CardThemeVariant light;
  final CardThemeVariant dark;

  const CardVisualTheme({
    required this.type,
    required this.label,
    required this.description,
    required this.tag,
    required this.light,
    required this.dark,
  });

  /// 根据上下文 brightness 选择变体
  CardThemeVariant resolve(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }
}
