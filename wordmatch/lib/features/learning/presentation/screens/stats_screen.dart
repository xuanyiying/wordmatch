import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/core/constants/app_colors.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/game/data/repositories/game_provider.dart';
import 'package:wordmatch/features/learning/domain/services/learning_stats_service.dart';
import 'package:wordmatch/shared/widgets/gradient_page_header.dart';

/// 学习统计页面
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  List<DailyLearningStat> _recent30Days = [];
  List<DailyLearningStat> _recent7Days = [];
  LearningSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = ref.read(progressStorageProvider);
    final results = await Future.wait([
      LearningStatsService.fetchRecentDays(storage, 30),
      LearningStatsService.fetchRecentDays(storage, 7),
      LearningStatsService.fetchSummary(storage),
    ]);

    if (!mounted) return;

    setState(() {
      _recent30Days = results[0] as List<DailyLearningStat>;
      _recent7Days = results[1] as List<DailyLearningStat>;
      _summary = results[2] as LearningSummary;
      _isLoading = false;
    });
  }

  Color _heatmapColor(int total) {
    if (total == 0) return const Color(0xFFEBEEE9);
    if (total <= 10) return AppColors.primaryGreen[100]!;
    if (total <= 30) return AppColors.primaryGreen[400]!;
    return AppColors.primaryGreen[700]!;
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$mm-$dd';
  }

  List<Widget> _buildHeatmapCells() {
    final cells = <Widget>[];
    for (int i = 0; i < 35; i++) {
      if (i < _recent30Days.length) {
        final stat = _recent30Days[i];
        cells.add(
          Tooltip(
            message: '${_formatDate(stat.date)}  新词${stat.newWords}  复习${stat.reviewWords}',
            child: Container(
              decoration: BoxDecoration(
                color: _heatmapColor(stat.total),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      } else {
        cells.add(
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const GradientPageHeader(
              title: '学习统计',
              subtitle: '每一次坚持都值得纪念',
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCards(),
                            const SizedBox(height: 28),
                            _buildHeatmapSection(),
                            const SizedBox(height: 28),
                            _buildCurveSection(),
                            const SizedBox(height: 16),
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

  Widget _buildSummaryCards() {
    final summary = _summary;
    final totalWords = summary?.totalWords ?? 0;
    final streakDays = summary?.streakDays ?? 0;
    final totalMinutes = summary?.totalMinutes ?? 0;
    final colors = context.appColors;
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.auto_awesome,
            color: colors.mintDeep,
            number: '$totalWords',
            label: '累计消灭',
            unit: '词',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.local_fire_department,
            color: AppColors.accentOrange,
            number: '$streakDays',
            label: '连续坚持',
            unit: '天',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.schedule,
            color: const Color(0xFF7C3AED),
            number: '$totalMinutes',
            label: '累计分钟',
            unit: '分',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color color,
    required String number,
    required String label,
    required String unit,
  }) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                number,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapSection() {
    final colors = context.appColors;
    final hasData = _recent30Days.any((s) => s.total > 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.grid_on_rounded,
                size: 18, color: colors.mintDeep),
            const SizedBox(width: 8),
            Text(
              '最近 30 天学习热力图',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '少  ',
              style: TextStyle(fontSize: 11, color: colors.inkSoft),
            ),
            Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFFEBEEE9), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.primaryGreen[100], borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.primaryGreen[400], borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.primaryGreen[700], borderRadius: BorderRadius.circular(2))),
            Text(
              '  多',
              style: TextStyle(fontSize: 11, color: colors.inkSoft),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.mintDeep.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: hasData
              ? GridView.count(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _buildHeatmapCells(),
                )
              : _buildEmptyState('完成学习后，这里会点亮你的坚持足迹'),
        ),
      ],
    );
  }

  Widget _buildCurveSection() {
    final colors = context.appColors;
    final hasData = _recent7Days.any((s) => s.total > 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.show_chart_rounded,
                size: 18, color: colors.mintDeep),
            const SizedBox(width: 8),
            Text(
              '最近 7 天学习曲线',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.mintDeep.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: hasData
              ? Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 180,
                      child: CustomPaint(
                        painter: _LearningCurvePainter(
                          stats: _recent7Days,
                          colors: colors,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _recent7Days.map((s) {
                        return Text(
                          _formatDate(s.date),
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.inkSoft,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                )
              : _buildEmptyState('完成学习后，这里会呈现你的进步曲线'),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 36,
            color: colors.inkSoft.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningCurvePainter extends CustomPainter {
  final List<DailyLearningStat> stats;
  final AppColorScheme colors;

  _LearningCurvePainter({required this.stats, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (stats.isEmpty) return;

    final width = size.width;
    final height = size.height;
    const paddingLeft = 36.0;
    const paddingRight = 12.0;
    const paddingTop = 16.0;
    const paddingBottom = 8.0;

    final chartWidth = width - paddingLeft - paddingRight;
    final chartHeight = height - paddingTop - paddingBottom;

    final values = stats.map((s) => s.total.toDouble()).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b) * 1.2;
    final safeMaxVal = maxVal == 0 ? 1 : maxVal;

    final xStep = chartWidth / (stats.length - 1);

    final points = <Offset>[];
    for (int i = 0; i < stats.length; i++) {
      final x = paddingLeft + i * xStep;
      final yRatio = values[i] / safeMaxVal;
      final y = paddingTop + chartHeight * (1 - yRatio);
      points.add(Offset(x, y));
    }

    final yAxisPaint = Paint()
      ..color = colors.border
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = colors.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = paddingTop + chartHeight * i / 4;
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(width - paddingRight, y),
        gridPaint,
      );
      final labelVal = (safeMaxVal * (4 - i) / 4).round();
      final labelPainter = TextPainter(
        text: TextSpan(
          text: '$labelVal',
          style: TextStyle(
            fontSize: 10,
            color: colors.inkSoft,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(paddingLeft - labelPainter.width - 6, y - labelPainter.height / 2),
      );
    }
    canvas.drawLine(
      Offset(paddingLeft, paddingTop),
      Offset(paddingLeft, paddingTop + chartHeight),
      yAxisPaint,
    );

    final path = Path();
    final fillPath = Path();

    if (points.length == 1) {
      path.moveTo(points.first.dx, points.first.dy);
    } else {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final cpx1 = prev.dx + (curr.dx - prev.dx) / 2;
        final cpy1 = prev.dy;
        final cpx2 = prev.dx + (curr.dx - prev.dx) / 2;
        final cpy2 = curr.dy;
        path.cubicTo(cpx1, cpy1, cpx2, cpy2, curr.dx, curr.dy);
      }
    }

    fillPath.addPath(path, Offset.zero);
    fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
    fillPath.lineTo(points.first.dx, paddingTop + chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors.mintDeep.withValues(alpha: 0.35),
          colors.mintDeep.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(
        paddingLeft,
        paddingTop,
        chartWidth,
        chartHeight,
      ));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.primaryGreen[700]!
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = AppColors.primaryGreen[700]!
      ..style = PaintingStyle.fill;
    final dotStrokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 5, dotStrokePaint);
      canvas.drawCircle(points[i], 3.5, dotPaint);

      if (values[i] > 0) {
        final valuePainter = TextPainter(
          text: TextSpan(
            text: '${values[i].toInt()}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen[800],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        valuePainter.paint(
          canvas,
          Offset(
            points[i].dx - valuePainter.width / 2,
            points[i].dy - valuePainter.height - 8,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LearningCurvePainter oldDelegate) {
    return oldDelegate.stats != stats;
  }
}
