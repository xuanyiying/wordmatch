import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wordmatch/core/theme/card_theme.dart';

/// 游戏背景画笔：绘制主题化的大气浮游元素
/// - Academic: 浮尘微粒 (向上缓慢漂浮的微小点)
/// - Forest: 光斑散景 (缓慢漂移的柔光圆)
/// - Space: 闪烁星场 (随机出现/消失的星点)
class GameBackgroundPainter extends CustomPainter {
  final CardThemeType themeType;
  final Color elementColor;
  final double animationValue; // 0→1 continuous

  GameBackgroundPainter({
    required this.themeType,
    required this.elementColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (themeType) {
      case CardThemeType.academic:
        _drawDustMotes(canvas, size);
        break;
      case CardThemeType.forest:
        _drawBokeh(canvas, size);
        break;
      case CardThemeType.space:
        _drawStarField(canvas, size);
        break;
    }
  }

  void _drawDustMotes(Canvas canvas, Size size) {
    final rand = Random(42); // fixed seed for consistency
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 12; i++) {
      final baseX = rand.nextDouble() * size.width;
      final baseY = rand.nextDouble() * size.height;
      // Slowly drift upward and wrap around
      final t = (animationValue + i * 0.08) % 1.0;
      final y = (baseY - t * size.height * 0.3) % size.height;
      final x = baseX + sin(t * pi * 2) * 5;
      final opacity = 0.06 + sin(t * pi) * 0.04;
      final r = 0.8 + rand.nextDouble() * 1.2;

      paint.color = elementColor.withValues(alpha: opacity.clamp(0.0, 0.15));
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _drawBokeh(Canvas canvas, Size size) {
    final rand = Random(42);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (var i = 0; i < 10; i++) {
      final baseX = rand.nextDouble() * size.width;
      final baseY = rand.nextDouble() * size.height;
      final t = (animationValue + i * 0.1) % 1.0;
      // Gentle drift with sway
      final x = baseX + sin(t * pi * 2 + i) * 15;
      final y = baseY + cos(t * pi * 1.5 + i * 0.7) * 10;
      final opacity = 0.04 + sin(t * pi) * 0.06;
      final r = 3.0 + rand.nextDouble() * 5.0;

      paint.color = elementColor.withValues(alpha: opacity.clamp(0.0, 0.12));
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _drawStarField(Canvas canvas, Size size) {
    final rand = Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 15; i++) {
      final baseX = rand.nextDouble() * size.width;
      final baseY = rand.nextDouble() * size.height;
      // Twinkle: appear and fade
      final phase = (animationValue * 2 + i * 0.13) % 1.0;
      final opacity = phase < 0.5
          ? phase * 2 * 0.12 // fade in
          : (1.0 - phase) * 2 * 0.12; // fade out
      final r = 0.5 + rand.nextDouble() * 1.5;

      paint.color = elementColor.withValues(alpha: opacity.clamp(0.0, 0.15));
      canvas.drawCircle(Offset(baseX, baseY), r, paint);

      // Larger stars get a cross-spike
      if (r > 1.2) {
        paint.strokeWidth = 0.3;
        paint.style = PaintingStyle.stroke;
        paint.color =
            elementColor.withValues(alpha: (opacity * 0.5).clamp(0.0, 0.1));
        final spikeLen = r * 3;
        canvas.drawLine(
          Offset(baseX - spikeLen, baseY),
          Offset(baseX + spikeLen, baseY),
          paint,
        );
        canvas.drawLine(
          Offset(baseX, baseY - spikeLen),
          Offset(baseX, baseY + spikeLen),
          paint,
        );
        paint.style = PaintingStyle.fill;
      }
    }
  }

  @override
  bool shouldRepaint(covariant GameBackgroundPainter old) {
    return animationValue != old.animationValue;
  }
}

/// 暗角叠加层：顶部/底部渐变，营造深度感
class VignetteOverlay extends StatelessWidget {
  final Color color;
  final double intensity; // 0.0-0.3

  const VignetteOverlay({
    super.key,
    required this.color,
    this.intensity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: intensity),
              Colors.transparent,
              Colors.transparent,
              color.withValues(alpha: intensity),
            ],
            stops: const [0.0, 0.2, 0.8, 1.0],
          ),
        ),
      ),
    );
  }
}
