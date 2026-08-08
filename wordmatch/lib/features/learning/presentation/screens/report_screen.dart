import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/core/constants/app_colors.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/constants/app_strings.dart';
import 'package:wordmatch/features/ai/data/services/ai_client.dart';
import 'package:wordmatch/features/ai/data/services/ai_report_service.dart';
import 'package:wordmatch/features/game/data/repositories/game_provider.dart';
import 'package:wordmatch/features/learning/domain/services/plan_service.dart';

/// 今日学习报告页面
class ReportScreen extends ConsumerStatefulWidget {
  final DailyTask dailyTask;

  const ReportScreen({super.key, required this.dailyTask});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  DailyAiReport? _aiReport;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAiReport();
  }

  Future<void> _loadAiReport() async {
    final task = widget.dailyTask;

    // 获取今日错词文本
    final wrongWordTexts = await _getTodayWrongWordTexts();

    final report = await AiReportService.generateDailyReport(
      completedNew: task.completedNew,
      completedReview: task.completedReview,
      wrongCount: task.wrongCount,
      accuracy: task.accuracy,
      wrongWords: wrongWordTexts,
    );

    if (!mounted) return;
    setState(() {
      _aiReport = report;
      _isLoading = false;
    });
  }

  Future<List<String>> _getTodayWrongWordTexts() async {
    final wrongWords = ref.read(progressStorageProvider).getWrongWords();
    if (wrongWords.isEmpty) return [];

    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final todayWrongIds = wrongWords
        .where((w) =>
            !w.lastWrongAt.isBefore(todayStart) &&
            w.lastWrongAt.isBefore(todayStart.add(const Duration(days: 1))))
        .map((w) => w.wordId)
        .toList();

    if (todayWrongIds.isEmpty) return [];

    try {
      final words = await ref.read(wordListProvider.future);
      final wordMap = {for (final w in words) w.id: w.word};
      return todayWrongIds
          .map((id) => wordMap[id])
          .where((word) => word != null && word.isNotEmpty)
          .cast<String>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(AppStrings.dailyReport),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePaddingH),
        child: Column(
          children: [
            const SizedBox(height: 32),

            // 完成图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              '今天又悄悄厉害了一点！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 32),

            // 统计卡片
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors.mintDeep.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.psychology_alt_rounded,
                        color: colors.mintDeep,
                        number: '${widget.dailyTask.completedNew}',
                        story: '位新朋友已经认识',
                        colors: colors,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        icon: Icons.handshake_rounded,
                        color: AppColors.accentOrange,
                        number: '${widget.dailyTask.completedReview}',
                        story: '位老朋友再次见面',
                        colors: colors,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFF7C3AED),
                        number: '${widget.dailyTask.maxCombo}x',
                        story: '连击高光时刻',
                        colors: colors,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        icon: Icons.favorite_border_rounded,
                        color: const Color(0xFFDB2777),
                        number:
                            '${(widget.dailyTask.accuracy * 100).toStringAsFixed(0)}%',
                        story: '彼此间的默契度',
                        colors: colors,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 进步提示卡
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.mintDeep.withValues(alpha: 0.08),
                      AppColors.success.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color:
                              colors.mintDeep.withValues(alpha: 0.12),
                          shape: BoxShape.circle),
                      child: Icon(Icons.trending_up_rounded,
                          color: colors.mintDeep, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '今日默契得分 ${widget.dailyTask.score}，每一分都是努力的小脚印 ✨',
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.mintDeep,
                            fontWeight: FontWeight.w500,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // AI 每日总结
            _buildAiReportCard(),

            const Spacer(),

            // 提示休息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bedtime, color: AppColors.accentOrange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '大脑正在偷偷把新认识的朋友刻进记忆里，给它一点时间，你真棒！',
                      style: TextStyle(
                        color: AppColors.accentOrange,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('返回首页'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiReportCard() {
    final colors = context.appColors;
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.mintDeep.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'AI 正在生成学习总结…',
              style: TextStyle(
                fontSize: 14,
                color: colors.inkSoft,
              ),
            ),
          ],
        ),
      );
    }

    if (_aiReport == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.mintDeep.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: colors.inkSoft.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AiClient.isConfigured
                    ? 'AI 总结生成失败，点击重试'
                    : '配置 API Key 后可查看 AI 每日总结',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.inkSoft.withValues(alpha: 0.8),
                ),
              ),
            ),
            if (AiClient.isConfigured)
              TextButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadAiReport();
                },
                child: const Text('重试'),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: colors.headerGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.mintDeep.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'AI 学习总结',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _aiReport!.encouragement,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.white,
            ),
          ),
          if (_aiReport!.weakPoints.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._aiReport!.weakPoints.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Text(
                        point,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_aiReport!.suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '明日建议',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ..._aiReport!.suggestions.map(
                    (suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('→ ',
                              style: TextStyle(color: Colors.white70)),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _buildStatCard({
  required IconData icon,
  required Color color,
  required String number,
  required String story,
  required AppColorScheme colors,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(number,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(story,
              style: TextStyle(
                  fontSize: 12,
                  color: colors.inkSoft,
                  height: 1.4)),
        ],
      ),
    ),
  );
}
