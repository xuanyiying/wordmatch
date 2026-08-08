import 'package:flutter/material.dart';
import 'package:wordmatch/core/theme/card_theme.dart';

/// v2 装饰层叠系统
/// 设计要点：
/// - 所有装饰都用 Stack + Positioned，不影响点击事件
/// - 装饰从 colors.decorations 读取，支持 3 主题差异化
/// - 选中态的 ribbon/badge 亮度脉动由 card_widget.dart 通过 AnimationController 注入
///
/// 装饰层 z-index 顺序（从下到上）：
///   0. 卡片底色渐变 (在 card_widget 里)
///   1. 顶部玻璃高光 (在 card_widget 里)
///   2. 3 色径向光斑 (BgBlobsLayer)
///   3. 散落主题图标群 11% 透明 (BgIconsLayer)
///   4. 内双框装饰 (FrameLayer)
///   5. 4 角 emoji 装饰 (CornersLayer)
///   6. 闪光 2-3 颗 (SparklesLayer)
///   7. 中心文字 (在 card_widget 里)
///   8. 底部反光带 (在 card_widget 里)

/// ============ 3 色径向光斑 ============
class BgBlobsLayer extends StatelessWidget {
  final List<Color> colors; // [白, 主题色, accent]
  final double size;

  const BgBlobsLayer({super.key, required this.colors, required this.size});

  @override
  Widget build(BuildContext context) {
    if (colors.length < 3) return const SizedBox.shrink();
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            // 左上白色高光光斑
            Positioned(
              top: -size * 0.2,
              left: -size * 0.2,
              width: size * 0.7,
              height: size * 0.7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors[0].withValues(alpha: 0.55),
                      colors[0].withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // 右下主题色光斑
            Positioned(
              bottom: -size * 0.2,
              right: -size * 0.15,
              width: size * 0.8,
              height: size * 0.8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors[1].withValues(alpha: 0.6),
                      colors[1].withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // 中央 accent 光斑
            Positioned(
              top: size * 0.35,
              left: size * 0.35,
              width: size * 0.4,
              height: size * 0.4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors[2].withValues(alpha: 0.4),
                      colors[2].withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============ 背景散落图标群（11% 透明） ============
class BgIconsLayer extends StatelessWidget {
  final List<BgIconSpec> icons;
  final double size;

  const BgIconsLayer({super.key, required this.icons, required this.size});

  @override
  Widget build(BuildContext context) {
    if (icons.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: icons
              .map((spec) => Positioned(
                    top: size * spec.topPercent / 100,
                    left: size * spec.leftPercent / 100,
                    child: Opacity(
                      opacity: 0.11,
                      child: Text(
                        spec.char,
                        style: TextStyle(fontSize: spec.fontSize),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

/// ============ 内双框装饰（dashed + double） ============
class FrameLayer extends StatelessWidget {
  final Color color;
  final double size;
  final double radius;

  const FrameLayer({
    super.key,
    required this.color,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Padding(
          padding: EdgeInsets.all(size * 0.05),
          child: CustomPaint(
            painter: _FramePainter(color: color, radius: radius - size * 0.05),
          ),
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  final Color color;
  final double radius;

  _FramePainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 外框（虚线感：用 dash 模拟）
    final outerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Radius.circular(radius),
    );
    _drawDashedRRect(canvas, outerRRect, paint);

    // 内框（实线）
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const inset = 3.0;
    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, canvasSize.width - inset * 2,
          canvasSize.height - inset * 2),
      Radius.circular(radius - inset),
    );
    canvas.drawRRect(innerRRect, innerPaint);
  }

  void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint) {
    final path = Path()..addRRect(rrect);
    const dashLength = 4.0;
    const gapLength = 3.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashLength),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) =>
      old.color != color || old.radius != radius;
}

/// ============ 4 角 emoji 装饰 ============
class CornersLayer extends StatelessWidget {
  final List<String> emojis;
  final double size;

  const CornersLayer({super.key, required this.emojis, required this.size});

  @override
  Widget build(BuildContext context) {
    if (emojis.length < 4) return const SizedBox.shrink();
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            _corner(emojis[0], size * 0.04, size * 0.04), // tl
            _corner(emojis[1], size * 0.04, size * 0.96,
                alignRight: true), // tr
            _corner(emojis[2], size * 0.96, size * 0.04,
                alignBottom: true), // bl
            _corner(emojis[3], size * 0.96, size * 0.96,
                alignRight: true, alignBottom: true), // br
          ],
        ),
      ),
    );
  }

  Widget _corner(String emoji, double topPercent, double leftPercent,
      {bool alignRight = false, bool alignBottom = false}) {
    return Positioned(
      top: alignBottom ? null : topPercent,
      left: alignRight ? null : leftPercent,
      right: alignRight ? (size - leftPercent) : null,
      bottom: alignBottom ? (size - topPercent) : null,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 10, height: 1.0),
      ),
    );
  }
}

/// ============ 闪光元素层 ============
class SparklesLayer extends StatelessWidget {
  final List<SparkleSpec> sparkles;
  final Color color;
  final double size;

  const SparklesLayer({
    super.key,
    required this.sparkles,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (sparkles.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: sparkles
              .map((spec) => Positioned(
                    top: size * spec.topPercent / 100,
                    left: size * spec.leftPercent / 100,
                    child: Text(
                      spec.char,
                      style: TextStyle(
                        fontSize: spec.fontSize,
                        color: color,
                        shadows: [
                          Shadow(
                            color: color.withValues(alpha: 0.95),
                            blurRadius: 6,
                          ),
                        ],
                        height: 1.0,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

/// ============ 匹配态印章（50px 绿对勾） ============
class MatchedSeal extends StatelessWidget {
  final Color color;
  final double size;

  const MatchedSeal({
    super.key,
    required this.color,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Transform.rotate(
          angle: -0.209, // -12°
          child: SizedBox(
            width: size + 12,
            height: size + 12,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 虚线环绕
                Container(
                  width: size + 10,
                  height: size + 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.6),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child:
                      CustomPaint(painter: _DashedCirclePainter(color: color)),
                ),
                // 主印章
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(color, Colors.white, 0.3)!,
                        Color.lerp(color, Colors.black, 0.3)!,
                      ],
                    ),
                    boxShadow: [
                      const BoxShadow(
                        color: Color(0x80FFFFFF),
                        blurRadius: 0,
                        offset: Offset(0, 1),
                      ),
                      BoxShadow(
                        color: color.withValues(alpha: 0.7),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '✓',
                      style: TextStyle(
                        fontSize: size * 0.55,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final circumference = 2 * 3.14159 * radius;
    const dashLength = 4.0;
    const gapLength = 3.0;

    double startAngle = 0;
    while (startAngle < circumference) {
      final start = startAngle / circumference * 2 * 3.14159;
      final end = (startAngle + dashLength) / circumference * 2 * 3.14159;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        end - start,
        false,
        paint,
      );
      startAngle += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) => old.color != color;
}

/// ============ 顶部玻璃高光 ============
class TopGloss extends StatelessWidget {
  final double size;

  const TopGloss({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: size * 0.03,
      left: size * 0.06,
      right: size * 0.06,
      height: size * 0.32,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.5),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(size * 0.2),
              bottom: const Radius.circular(100),
            ),
          ),
        ),
      ),
    );
  }
}

/// ============ 底部反光带 ============
class BottomGloss extends StatelessWidget {
  final double size;

  const BottomGloss({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: size * 0.03,
      left: size * 0.1,
      right: size * 0.1,
      height: size * 0.1,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.18),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(100),
              bottom: Radius.circular(size * 0.2),
            ),
          ),
        ),
      ),
    );
  }
}
