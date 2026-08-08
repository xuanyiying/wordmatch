import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wordmatch/core/theme/card_theme.dart';

/// Burst particle data
class BurstParticle {
  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;

  const BurstParticle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

/// 匹配成功粒子爆裂效果
class MatchBurstEffect extends StatefulWidget {
  final Offset center;
  final CardThemeType themeType;
  final List<Color> burstColors;

  const MatchBurstEffect({
    super.key,
    required this.center,
    required this.themeType,
    required this.burstColors,
  });

  @override
  State<MatchBurstEffect> createState() => _MatchBurstEffectState();
}

class _MatchBurstEffectState extends State<MatchBurstEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<BurstParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _particles = _generateParticles();
    _controller.forward().then((_) {
      if (mounted) setState(() {});
    });
  }

  List<BurstParticle> _generateParticles() {
    final rand = Random(widget.center.hashCode);
    final particles = <BurstParticle>[];
    const count = 10;

    for (var i = 0; i < count; i++) {
      final angle = (i / count) * pi * 2 + rand.nextDouble() * 0.5;
      final speed = 20.0 + rand.nextDouble() * 30.0;
      final color = widget.burstColors[i % widget.burstColors.length];
      final size = 3.0 + rand.nextDouble() * 4.0;

      particles.add(BurstParticle(
        angle: angle,
        speed: speed,
        color: color,
        size: size,
        rotation: rand.nextDouble() * pi * 2,
        rotationSpeed: (rand.nextDouble() - 0.5) * 0.15,
      ));
    }
    return particles;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isCompleted) return const SizedBox.shrink();

    return Positioned(
      left: widget.center.dx,
      top: widget.center.dy,
      child: CustomPaint(
        painter: MatchBurstPainter(
          particles: _particles,
          animationValue: _controller.value,
          themeType: widget.themeType,
        ),
        size: const Size(100, 100),
      ),
    );
  }
}

/// 粒子爆裂画笔
class MatchBurstPainter extends CustomPainter {
  final List<BurstParticle> particles;
  final double animationValue; // 0→1
  final CardThemeType themeType;

  MatchBurstPainter({
    required this.particles,
    required this.animationValue,
    required this.themeType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final t = animationValue;

    for (final p in particles) {
      final distance = p.speed * t;
      final dx = cos(p.angle) * distance;
      final dy = sin(p.angle) * distance;
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final currentRotation = p.rotation + p.rotationSpeed * t * 10;

      canvas.save();
      canvas.translate(center.dx + dx, center.dy + dy);
      canvas.rotate(currentRotation);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      switch (themeType) {
        case CardThemeType.academic:
          // Paper scraps: small rectangles
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: p.size * (1 - t * 0.3),
            height: p.size * 0.6 * (1 - t * 0.3),
          );
          canvas.drawRect(rect, paint);
          break;
        case CardThemeType.forest:
          // Falling leaves: small ovals with sway
          final sway = sin(t * pi * 2) * 5;
          final ovalRect = Rect.fromCenter(
            center: Offset(sway, t * 10), // drift downward
            width: p.size * (1 - t * 0.2),
            height: p.size * 0.7 * (1 - t * 0.2),
          );
          canvas.drawOval(ovalRect, paint);
          break;
        case CardThemeType.space:
          // Stardust: small circles with twinkle
          final twinkle =
              t < 0.5 ? opacity : opacity * (0.5 + 0.5 * sin(t * pi * 4));
          paint.color = p.color.withValues(alpha: twinkle * 0.9);
          canvas.drawCircle(
            Offset.zero,
            p.size * 0.5 * (1 - t * 0.4),
            paint,
          );
          // Glow
          final glowPaint = Paint()
            ..color = p.color.withValues(alpha: twinkle * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          canvas.drawCircle(
            Offset.zero,
            p.size * (1 - t * 0.2),
            glowPaint,
          );
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant MatchBurstPainter old) {
    return animationValue != old.animationValue;
  }
}
