import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/learning/data/providers/study_reminder_provider.dart';
import 'package:wordmatch/features/learning/data/services/study_reminder_repository.dart';
import 'package:wordmatch/shared/widgets/gradient_page_header.dart';

/// 学习提醒设置页
///
/// 提供每日定时学习提醒的开关与时间设置，通过 [studyReminderProvider]
/// 持久化并同步调度本地通知。
class StudyReminderScreen extends ConsumerStatefulWidget {
  const StudyReminderScreen({super.key});

  @override
  ConsumerState<StudyReminderScreen> createState() =>
      _StudyReminderScreenState();
}

class _StudyReminderScreenState extends ConsumerState<StudyReminderScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final settings = ref.watch(studyReminderProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const GradientPageHeader(
              title: '学习提醒',
              subtitle: '每天定时提醒你完成今日学习',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSwitchCard(context, settings),
                  const SizedBox(height: 16),
                  _buildTimeCard(context, settings),
                  const SizedBox(height: 16),
                  _buildTipCard(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 总开关
  Widget _buildSwitchCard(
      BuildContext context, StudyReminderSettings settings) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.mintDeep.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.notifications_active_rounded,
                color: colors.mintDeep, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('开启学习提醒',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('到点提醒你背单词',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Switch(
            value: settings.enabled,
            onChanged: _saving ? null : (v) => _toggle(v),
            activeThumbColor: colors.mintDeep,
          ),
        ],
      ),
    );
  }

  /// 提醒时间选择
  Widget _buildTimeCard(
      BuildContext context, StudyReminderSettings settings) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: settings.enabled
            ? () => _pickTime(context, settings)
            : null,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.amberBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.access_time_rounded,
                  color: Color(0xFFD4900A), size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('提醒时间',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('点击选择每天提醒时刻',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Text(
              settings.timeLabel,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: settings.enabled ? colors.mintDeep : colors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 说明卡片
  Widget _buildTipCard(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.amberBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded,
              color: Color(0xFFD4900A), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '小提示：开启提醒后，请允许系统通知权限，否则无法按时收到提醒。',
              style: TextStyle(fontSize: 13, color: colors.ink, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(bool value) async {
    if (_saving) return;
    setState(() => _saving = true);
    await ref.read(studyReminderProvider.notifier).toggle(value);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(value ? '已开启学习提醒' : '已关闭学习提醒'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _pickTime(
      BuildContext context, StudyReminderSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
      helpText: '选择提醒时间',
    );
    if (picked == null) return;
    await ref
        .read(studyReminderProvider.notifier)
        .setTime(hour: picked.hour, minute: picked.minute);
  }
}
