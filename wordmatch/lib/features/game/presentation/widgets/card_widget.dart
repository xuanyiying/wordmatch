import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/theme/card_theme.dart';
import 'package:wordmatch/core/theme/card_theme_registry.dart';
import 'package:wordmatch/features/game/data/models/game_card.dart';
import 'package:wordmatch/features/game/presentation/widgets/card_decorators.dart';

/// 主题化卡片组件 v2：高吸引感多层装饰
/// 核心特性：
/// - 5 层阴影叠（内顶高光 + 内底投影 + 边缘高光 + 短投影 + 长投影）
/// - 渐变金属描边
/// - 3 色径向光斑 + 11% 散落主题图标群
/// - 4 角 emoji 装饰 + 3D 徽章 + 3D 缎带
/// - 选中态 Option D：1.6s 持续呼吸（scale + 缎带/徽章亮度脉动）
/// - 匹配态：灰阶 + 50px 绿印章
class CardWidget extends StatefulWidget {
  final GameCard card;
  final double width;
  final double height;
  final CardThemeType themeType;
  final VoidCallback? onTap;

  const CardWidget({
    super.key,
    required this.card,
    required this.width,
    required this.height,
    this.themeType = CardThemeType.academic,
    this.onTap,
  });

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _breatheController; // Option D 持续呼吸
  late AnimationController _idleController;

  /// 装饰层使用较小的边作为基准，保证视觉元素不会被裁切
  double get _visualSize => widget.width < widget.height ? widget.width : widget.height;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: AppSizes.shakeDurationMs),
      vsync: this,
    );
    _breatheController = AnimationController(
      duration: const Duration(milliseconds: 1600), // Option D: 1.6s
      vsync: this,
    );
    _initIdleController();
    _startIdleIfNeeded();
  }

  void _initIdleController() {
    final period = _idlePeriodMs;
    _idleController = AnimationController(
      duration: Duration(milliseconds: period),
      vsync: this,
    );
  }

  int get _idlePeriodMs {
    switch (widget.themeType) {
      case CardThemeType.academic:
        return 3000;
      case CardThemeType.forest:
        return 4000;
      case CardThemeType.space:
        return 5000;
    }
  }

  void _startIdleIfNeeded() {
    if (widget.card.state == CardState.revealed) {
      if (!_idleController.isAnimating) {
        _idleController.repeat(reverse: true);
      }
    }
  }

  @override
  void didUpdateWidget(CardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.card.state == CardState.shaking &&
        oldWidget.card.state != CardState.shaking) {
      _shakeController.forward(from: 0);
    }
    if (widget.card.state == CardState.selected) {
      _idleController.stop();
      if (!_breatheController.isAnimating) {
        _breatheController.repeat(reverse: true);
      }
    } else if (widget.card.state == CardState.matched) {
      _idleController.stop();
      _breatheController.stop();
      _breatheController.value = 0;
    } else {
      _breatheController.stop();
      _breatheController.value = 0;
      _startIdleIfNeeded();
    }
    if (oldWidget.themeType != widget.themeType) {
      _idleController.dispose();
      _initIdleController();
      _startIdleIfNeeded();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _breatheController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.card.state == CardState.selected;
    final isMatched = widget.card.isMatched;

    // RepaintBoundary 限制单张卡片的重绘边界，避免呼吸动画触发整个 Grid 重绘
    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        child: _buildCard(isSelected, isMatched),
      ),
    );
  }

  Widget _buildCard(bool isSelected, bool isMatched) {
    final isTypeA = widget.card.type == CardType.typeA;
    final themeData = CardThemeRegistry.get(widget.themeType);
    final variant = themeData.resolve(context);
    final colors = _resolveColors(variant, isTypeA, isSelected, isMatched);
    final borderRadius = _visualSize * 0.2;
    // 静态卡片主体作为 child 传入 AnimatedBuilder，避免每次 tick 重建内部装饰
    final cardBody = _buildStaticCardBody(
      colors,
      variant,
      isTypeA,
      isMatched,
      borderRadius,
    );

    return AnimatedBuilder(
      animation: Listenable.merge(
          [_shakeController, _breatheController, _idleController]),
      builder: (context, child) {
        final shakeOffset = _shakeController.isAnimating
            ? sin(_shakeController.value * pi * 4) * 4
            : 0.0;

        // idle 动画（未选中/未匹配时）
        final idleTransform = _buildIdleTransform(isSelected, isMatched);

        // Option D：选中态持续呼吸 scale 1.10↔1.13
        double scale = 1.0;
        double translateY = 0.0;
        double rotateRad = 0.0;
        if (isMatched) {
          scale = 0.92;
        } else if (isSelected) {
          scale = 1.10 + _breatheController.value * 0.03;
          translateY = -8.0;
          rotateRad = -0.052; // -3°
        }

        final breathe = isSelected ? _breatheController.value : 0.0;

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: Transform(
            alignment: Alignment.center,
            transform: idleTransform
              ..translateByDouble(0.0, translateY, 0.0, 1.0)
              ..rotateZ(rotateRad)
              ..scaleByDouble(scale, scale, 1.0, 1.0),
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSelected
                        ? const [
                            Color(0xFFFFE9A8),
                            Color(0xFFFFD66B),
                            Color(0xFFFFB93F),
                            Color(0xFFFFE9A8),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.85),
                            colors.border.withValues(alpha: 0.4),
                            colors.border,
                            Colors.white.withValues(alpha: 0.6),
                          ],
                  ),
                  boxShadow: _buildOuterShadows(colors, isSelected, breathe),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: cardBody,
    );
  }

  List<BoxShadow> _buildOuterShadows(
    CardStateColors colors,
    bool isSelected,
    double breathe,
  ) {
    final shadows = <BoxShadow>[
      // 第 1 层：1px 边缘高光
      BoxShadow(
        color: Colors.white.withValues(alpha: isSelected ? 0.6 : 0.45),
        blurRadius: 0,
        offset: const Offset(0, 1),
      ),
      // 第 2 层：8px 短投影
      BoxShadow(
        color: colors.border.withValues(alpha: 0.30),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
      // 第 3 层：20px 长投影
      BoxShadow(
        color: colors.border.withValues(alpha: 0.22),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ];

    // 选中态：金色环 + 主题色强光晕（呼吸同步）
    if (isSelected) {
      final glowAlpha = 0.5 + breathe * 0.4;
      shadows.add(
        BoxShadow(
          color: const Color(0xFFFFD66B).withValues(alpha: glowAlpha),
          blurRadius: 12 + breathe * 6,
          spreadRadius: 1,
        ),
      );
      shadows.add(
        BoxShadow(
          color: colors.border.withValues(alpha: 0.6 + breathe * 0.3),
          blurRadius: 28 + breathe * 12,
          spreadRadius: 0,
        ),
      );
    }

    return shadows;
  }

  Widget _buildStaticCardBody(
    CardStateColors colors,
    CardThemeVariant variant,
    bool isTypeA,
    bool isMatched,
    double borderRadius,
  ) {
    final decorations = colors.decorations;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius - 1.5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius - 1.5),
          gradient: colors.gradient,
          color: colors.gradient == null
              ? colors.background.withValues(alpha: colors.opacity)
              : null,
        ),
        child: Stack(
          children: [
            // ===== z-index 1: 顶部玻璃高光 =====
            if (!isMatched) TopGloss(size: _visualSize),

            // ===== z-index 2: 3 色径向光斑 =====
            if (!isMatched && decorations != null)
              BgBlobsLayer(
                colors: decorations.bgBlobColors,
                size: _visualSize,
              ),

            // ===== z-index 3: 散落主题图标群（11% 透明） =====
            if (!isMatched && decorations != null)
              BgIconsLayer(
                icons: decorations.bgIcons,
                size: _visualSize,
              ),

            // ===== z-index 4: 内双框装饰 =====
            if (!isMatched && decorations != null)
              FrameLayer(
                color: decorations.frameColor,
                size: _visualSize,
                radius: borderRadius,
              ),

            // ===== z-index 5: 4 角 emoji =====
            if (!isMatched && decorations != null)
              CornersLayer(
                emojis: decorations.cornerEmojis,
                size: _visualSize,
              ),

            // ===== z-index 6: 闪光 2-3 颗 =====
            if (!isMatched && decorations != null)
              SparklesLayer(
                sparkles: decorations.sparkles,
                color: decorations.sparkleColor,
                size: _visualSize,
              ),

            // ===== z-index 9: 中心文字 =====
            _buildCardContent(colors, isTypeA, isMatched),

            // ===== z-index 10: 底部反光带 =====
            if (!isMatched) BottomGloss(size: _visualSize),

            // ===== z-index 11: 匹配印章 =====
            if (isMatched && decorations != null)
              MatchedSeal(
                color: decorations.sealColor,
                size: _visualSize * 0.45,
              ),
          ],
        ),
      ),
    );
  }

  /// 去除释义中的词性前缀，如 "vt. 放弃" → "放弃"
  String _stripPartOfSpeech(String text) {
    return text
        .replaceFirst(
          RegExp(
            r'^\s*(n|v|vt|vi|adj|adv|prep|conj|pron|art|int|num|aux|modal|det)\s*\.\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  /// 将释义按分号拆分；若超过 2 条，基于 itemId 稳定随机选取 2 条
  List<String> _prepareMeaningLines(String text) {
    final parts = text
        .split(RegExp(r'[;；]'))
        .map(_stripPartOfSpeech)
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length <= 2) return parts;

    final random = Random(widget.card.itemId.hashCode);
    parts.shuffle(random);
    return parts.take(2).toList();
  }

  /// 卡片内容（文字）
  Widget _buildCardContent(
    CardStateColors colors,
    bool isTypeA,
    bool isMatched,
  ) {
    final textDecoration = isMatched
        ? TextDecoration.lineThrough
        : (colors.useLineThrough ? TextDecoration.lineThrough : null);
    final textColor =
        isMatched ? colors.text.withValues(alpha: 0.5) : colors.text;

    // 释义卡片：含分号时拆分为多行显示，避免单行长文本导致字体过小
    final displayText =
        isTypeA ? widget.card.text : _stripPartOfSpeech(widget.card.text);
    final meaningLines =
        !isTypeA ? _prepareMeaningLines(widget.card.text) : <String>[];
    final showMultiLine = !isTypeA && meaningLines.length > 1;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showMultiLine)
              ...meaningLines.map(
                (line) => Flexible(
                  child: _AutoSizedText(
                    text: line,
                    baseFontSize: AppSizes.cardMeaningSize,
                    color: textColor,
                    fontWeight: colors.fontWeight,
                    fontFamily: colors.fontFamily,
                    decoration: textDecoration,
                    maxWidth: widget.width - 16,
                    textShadow: colors.textShadow,
                    maxLines: 1,
                  ),
                ),
              )
            else
              Flexible(
                child: _AutoSizedText(
                  text: displayText,
                  baseFontSize: isTypeA
                      ? AppSizes.cardWordSize
                      : AppSizes.cardMeaningSize,
                  color: textColor,
                  fontWeight: colors.fontWeight,
                  fontFamily: colors.fontFamily,
                  decoration: textDecoration,
                  maxWidth: widget.width - 16,
                  textShadow: colors.textShadow,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 基于 itemId 哈希稳定随机选取配色，不区分单词/释义
  CardStateColors _resolveColors(
    CardThemeVariant variant,
    bool isTypeA,
    bool isSelected,
    bool isMatched,
  ) {
    if (isMatched) return variant.matched;
    final colorIndex = widget.card.itemId.hashCode.abs() % 2;
    if (isSelected) {
      return colorIndex == 0 ? variant.typeASelected : variant.typeBSelected;
    }
    return colorIndex == 0 ? variant.typeAIdle : variant.typeBIdle;
  }

  /// 构建闲置微动画 transform
  Matrix4 _buildIdleTransform(bool isSelected, bool isMatched) {
    if (isSelected || isMatched) return Matrix4.identity();

    final t = _idleController.value; // 0..1..0
    final idleAnim =
        CardThemeRegistry.get(widget.themeType).light.idleAnimation;

    switch (idleAnim) {
      case IdleAnimationType.paperFlutter:
        final scaleY = 0.98 + t * 0.02;
        return Matrix4.identity()..scaleByDouble(1.0, scaleY, 1.0, 1.0);

      case IdleAnimationType.organicBreathe:
        final scale = 0.97 + t * 0.03;
        final rotation = (t - 0.5) * 0.0087;
        final m = Matrix4.identity();
        m.setRotationZ(rotation);
        m.scaleByDouble(scale, scale, 1.0, 1.0);
        return m;

      case IdleAnimationType.floatShimmer:
        final yShift = (t - 0.5) * 2.0;
        return Matrix4.identity()..translateByDouble(0.0, yShift, 0.0, 1.0);
    }
  }
}

/// 自适应字号文本组件
class _AutoSizedText extends StatelessWidget {
  final String text;
  final double baseFontSize;
  final Color color;
  final FontWeight fontWeight;
  final String? fontFamily;
  final TextDecoration? decoration;
  final double maxWidth;
  final Shadow? textShadow;
  final int? maxLines;

  const _AutoSizedText({
    required this.text,
    required this.baseFontSize,
    required this.color,
    required this.fontWeight,
    this.fontFamily,
    this.decoration,
    required this.maxWidth,
    this.textShadow,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final charCount = text.length;

    final double scaleFactor;
    final int effectiveMaxLines;
    if (maxLines != null) {
      effectiveMaxLines = maxLines!;
      if (charCount <= 2) {
        scaleFactor = 1.4;
      } else if (charCount <= 4) {
        scaleFactor = 1.15;
      } else if (charCount <= 6) {
        scaleFactor = 1.0;
      } else if (charCount <= 10) {
        scaleFactor = 0.85;
      } else {
        scaleFactor = 0.7;
      }
    } else if (charCount <= 2) {
      scaleFactor = 1.4;
      effectiveMaxLines = 1;
    } else if (charCount <= 4) {
      scaleFactor = 1.15;
      effectiveMaxLines = 1;
    } else if (charCount <= 6) {
      scaleFactor = 1.0;
      effectiveMaxLines = 1;
    } else if (charCount <= 10) {
      scaleFactor = 0.85;
      effectiveMaxLines = 2;
    } else {
      scaleFactor = 0.7;
      effectiveMaxLines = 3;
    }

    final fontSize = baseFontSize * scaleFactor;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
          decoration: decoration,
          height: 1.3,
          shadows: textShadow != null ? [textShadow!] : null,
        ),
        textAlign: TextAlign.center,
        maxLines: effectiveMaxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
