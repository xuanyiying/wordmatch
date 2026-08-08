import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 单词消消乐 Logo — 2x2 消除网格 + 爆裂特效
///
/// 品牌色: 亮绿 #9FE870 / 深绿 #163300 / 暖琥珀 #FFB800
class AppLogoPainter extends CustomPainter {
  /// 是否绘制文字（App Icon 不需要文字，Splash Screen 需要）
  final bool showText;

  /// 爆裂粒子动画进度 0~1（0=静态图标，1=粒子散开）
  final double burstProgress;

  AppLogoPainter({this.showText = false, this.burstProgress = 0.0});

  // 品牌色
  static const Color brightGreen = Color(0xFF9FE870);
  static const Color darkGreen = Color(0xFF163300);
  static const Color amber = Color(0xFFFFB800);
  static const Color bgGreen = Color(0xFFF2FFE8);
  static const Color lightSurface = Color(0xFFE8EBE6);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // 背景：深绿圆角矩形
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, s, s),
      Radius.circular(s * 0.22),
    );
    canvas.drawRRect(bgRect, Paint()..color = darkGreen);

    // 内部浅色背景区域
    final innerPadding = s * 0.08;
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(innerPadding, innerPadding, s - innerPadding * 2,
          s - innerPadding * 2),
      Radius.circular(s * 0.16),
    );
    canvas.drawRRect(innerRect, Paint()..color = bgGreen);

    // 2x2 网格参数
    final gridArea = Rect.fromLTWH(
      s * 0.16,
      s * 0.16,
      s * 0.68,
      s * 0.68,
    );
    final cellW = gridArea.width / 2;
    final cellH = gridArea.height / 2;
    final gap = s * 0.04;
    final cardRadius = Radius.circular(s * 0.06);

    // 卡牌数据: [row, col, text, bgColor, textColor, isMatched]
    final cards = [
      // Row 0
      [0, 0, 'E', brightGreen, darkGreen, false],
      [0, 1, '预', Colors.white, darkGreen, false],
      // Row 1
      [1, 0, 'M', brightGreen, darkGreen, false],
      [1, 1, '测', lightSurface, darkGreen, true], // 已消除
    ];

    for (final card in cards) {
      final row = card[0] as int;
      final col = card[1] as int;
      final text = card[2] as String;
      final bgColor = card[3] as Color;
      final textColor = card[4] as Color;
      final isMatched = card[5] as bool;

      final x = gridArea.left + col * cellW + gap / 2;
      final y = gridArea.top + row * cellH + gap / 2;
      final w = cellW - gap;
      final h = cellH - gap;

      final cardRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        cardRadius,
      );

      if (isMatched) {
        // 已消除卡牌：缩小 + 半透明 + 爆裂粒子
        _drawMatchedCard(canvas, cardRect, bgColor, s, burstProgress);
      } else {
        // 正常卡牌
        // 卡片阴影
        canvas.drawRRect(
          cardRect.shift(const Offset(0, 4)),
          Paint()..color = const Color(0x14000000),
        );

        // 卡片本体
        final cardPaint = Paint()..color = bgColor;
        canvas.drawRRect(cardRect, cardPaint);

        // 卡片边框
        canvas.drawRRect(
          cardRect,
          Paint()
            ..color = darkGreen.withValues(alpha: 0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.006,
        );

        // 文字
        final textStyle = ui.TextStyle(
          color: textColor,
          fontSize: s * 0.14,
          fontWeight: ui.FontWeight.w900,
        );
        final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: ui.TextAlign.center,
          fontSize: s * 0.14,
        ))
          ..pushStyle(textStyle)
          ..addText(text);
        final paragraph = paragraphBuilder.build();
        paragraph.layout(ui.ParagraphConstraints(width: w));
        canvas.drawParagraph(
          paragraph,
          Offset(x + (w - paragraph.maxIntrinsicWidth) / 2,
              y + (h - paragraph.height) / 2),
        );
      }
    }

    // 在 (0,0) 和 (0,1) 之间画一条匹配连线指示
    _drawMatchLine(canvas, gridArea, cellW, cellH, gap, s);

    // 爆裂粒子（已消除卡位置）
    if (burstProgress > 0) {
      _drawBurstParticles(
          canvas, gridArea, cellW, cellH, gap, s, burstProgress);
    }

    // 文字区域（可选）
    if (showText) {
      _drawText(canvas, s);
    }
  }

  void _drawMatchedCard(
      Canvas canvas, RRect cardRect, Color bgColor, double s, double progress) {
    // 缩小效果
    final scale = 1.0 - progress * 0.3;
    final alpha = 1.0 - progress * 0.6;

    final centerX = cardRect.left + cardRect.width / 2;
    final centerY = cardRect.top + cardRect.height / 2;
    final scaledW = cardRect.width * scale;
    final scaledH = cardRect.height * scale;

    final scaledRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(centerX, centerY), width: scaledW, height: scaledH),
      Radius.circular(cardRect.tlRadiusX * scale),
    );

    canvas.drawRRect(
      scaledRect,
      Paint()..color = bgColor.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );

    // 发光环
    final glowPaint = Paint()
      ..color =
          brightGreen.withValues(alpha: (0.5 - progress * 0.5).clamp(0.0, 0.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.02;
    canvas.drawRRect(scaledRect, glowPaint);
  }

  void _drawMatchLine(
    Canvas canvas,
    Rect gridArea,
    double cellW,
    double cellH,
    double gap,
    double s,
  ) {
    // 连线：从第一行左卡右边到第一行右卡左边
    final y = gridArea.top + cellH / 2;
    final x1 = gridArea.left + cellW - gap / 2 + s * 0.02;
    final x2 = gridArea.left + cellW + gap / 2 - s * 0.02;

    final linePaint = Paint()
      ..color = amber.withValues(alpha: 0.6)
      ..strokeWidth = s * 0.016
      ..strokeCap = ui.StrokeCap.round;

    canvas.drawLine(Offset(x1, y), Offset(x2, y), linePaint);

    // 小闪光点
    final dotPaint = Paint()..color = amber;
    canvas.drawCircle(Offset((x1 + x2) / 2, y), s * 0.012, dotPaint);
  }

  void _drawBurstParticles(
    Canvas canvas,
    Rect gridArea,
    double cellW,
    double cellH,
    double gap,
    double s,
    double progress,
  ) {
    // 从已消除卡位置（row=1, col=1）爆出8个粒子
    final cx = gridArea.left + 1 * cellW + cellW / 2;
    final cy = gridArea.top + 1 * cellH + cellH / 2;

    final particleColors = [
      brightGreen,
      amber,
      darkGreen,
      Colors.white,
      brightGreen,
      amber,
      darkGreen,
      Colors.white,
    ];

    for (int i = 0; i < 8; i++) {
      final angle = i * 45.0 * 3.14159 / 180.0;
      final dist = s * 0.05 + progress * s * 0.12;
      final px = cx + dist * math.cos(angle);
      final py = cy + dist * math.sin(angle);
      final radius = s * 0.02 * (1.0 - progress * 0.5);
      final alpha = (1.0 - progress * 0.7).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(px, py),
        radius,
        Paint()..color = particleColors[i].withValues(alpha: alpha),
      );
    }
  }

  void _drawText(Canvas canvas, double s) {
    // WordMatch 文字
    final titleStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: s * 0.07,
      fontWeight: ui.FontWeight.w900,
      letterSpacing: s * 0.005,
    );
    final titleBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: ui.TextAlign.center,
      fontSize: s * 0.07,
    ))
      ..pushStyle(titleStyle)
      ..addText('WordMatch');
    final titlePara = titleBuilder.build();
    titlePara.layout(ui.ParagraphConstraints(width: s));
    canvas.drawParagraph(titlePara, Offset(0, s * 0.88));

    // 中文副标题
    final subStyle = ui.TextStyle(
      color: brightGreen,
      fontSize: s * 0.04,
      fontWeight: ui.FontWeight.w600,
    );
    final subBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: ui.TextAlign.center,
      fontSize: s * 0.04,
    ))
      ..pushStyle(subStyle)
      ..addText('单词消消乐');
    final subPara = subBuilder.build();
    subPara.layout(ui.ParagraphConstraints(width: s));
    canvas.drawParagraph(subPara, Offset(0, s * 0.95));
  }

  @override
  bool shouldRepaint(covariant AppLogoPainter oldDelegate) =>
      oldDelegate.burstProgress != burstProgress ||
      oldDelegate.showText != showText;
}

/// Logo 组件（带可选动画）
class AppLogo extends StatefulWidget {
  final double size;
  final bool showText;
  final bool animate;

  const AppLogo({
    super.key,
    this.size = 200,
    this.showText = false,
    this.animate = true,
  });

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _burstAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _burstAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.animate) {
      // 延迟启动爆裂动画，让用户先看到完整网格
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: AppLogoPainter(
        showText: widget.showText,
        burstProgress: widget.animate ? _burstAnim.value : 0.0,
      ),
    );
  }
}

/// 静态 Logo Widget（用于 App Icon 渲染等不需要动画的场景）
class AppLogoStatic extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogoStatic({super.key, this.size = 200, this.showText = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: AppLogoPainter(showText: showText, burstProgress: 0.0),
    );
  }
}
