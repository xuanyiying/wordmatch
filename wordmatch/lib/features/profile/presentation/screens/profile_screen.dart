import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/core/router/app_router.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/core/subscription/subscription_provider.dart';
import 'package:wordmatch/core/subscription/subscription_service.dart';
import 'package:wordmatch/core/subscription/subscription_tier.dart';
import 'package:wordmatch/core/subscription/upgrade_pro_dialog.dart';
import 'package:wordmatch/features/game/data/repositories/game_provider.dart';
import 'package:wordmatch/shared/utils/haptic_util.dart';
import 'package:wordmatch/shared/widgets/gradient_page_header.dart';

/// 我的页：统计卡 + Pro 会员 + 功能入口列表
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _learned = 0;
  int _mastered = 0;
  int _streak = 0;
  int _wrongCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final storage = ref.read(progressStorageProvider);
    if (mounted) {
      setState(() {
        _learned = storage.getLearnedCount();
        _mastered = storage.getMasteredCount();
        _streak = storage.getStreakDays();
        _wrongCount = storage.getWrongWordCount();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _initData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          _buildStatCard(),
                          const SizedBox(height: 12),
                          _buildProCard(),
                          const SizedBox(height: 12),
                          _buildListCard(),
                          const SizedBox(height: 14),
                          Text('WordMatch v1.0.0',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 10, color: colors.inkFaint)),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = context.appColors;
    return GradientPageHeader(
      title: '学习者',
      subtitle: _streak > 0 ? '已陪伴你 $_streak 天' : '开始你的学习之旅',
      showBackButton: false,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [colors.mintLight, colors.mintDeep]),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildStatCard() {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          _statItem('$_learned', '已学习', colors.ink, colors),
          _statDivider(colors),
          _statItem('$_mastered', '已掌握', colors.mintDeep, colors),
          _statDivider(colors),
          _statItem('$_streak', '连续天数', colors.amber, colors),
        ],
      ),
    );
  }

  Widget _statItem(
      String num, String lbl, Color color, AppColorScheme colors) {
    return Expanded(
      child: Column(
        children: [
          Text(num,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(lbl,
              style: TextStyle(fontSize: 11, color: colors.inkSoft)),
        ],
      ),
    );
  }

  Widget _statDivider(AppColorScheme colors) =>
      Container(width: 1, height: 30, color: colors.border);

  Widget _buildProCard() {
    // 商业化关闭时不显示
    if (!SubscriptionService.kCommercialEnabled) {
      return const SizedBox.shrink();
    }
    return Consumer(
      builder: (ctx, ref, _) {
        final tierAsync = ref.watch(tierProvider);
        return tierAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (tier) {
            if (tier.isPro) return const SizedBox.shrink();
            return InkWell(
              onTap: () async {
                HapticUtil.buttonTap();
                final ok = await showUpgradeProDialog(context);
                if (ok == true) {
                  ref.invalidate(tierProvider);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF9B7EE8), Color(0xFFC86DD7)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.workspace_premium,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('升级 WordMatch Pro',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text('AI 助记无限 · 词串烧无限生成',
                              style: TextStyle(
                                  color: Color(0xD9FFFFFF),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999)),
                      child: const Text('¥108 终身',
                          style: TextStyle(
                              color: Color(0xFF8B5CE8),
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListCard() {
    final colors = context.appColors;
    final items = <Widget>[
      _listItem(
        icon: Icons.menu_book,
        bg: colors.mintBg,
        iconColor: colors.mintDeep,
        title: '词库管理',
        subtitle: '切换或导入词库',
        onTap: () =>
            Navigator.pushNamed(context, AppRouter.wordbookSelect),
      ),
      _listItem(
        icon: Icons.error_outline,
        bg: const Color(0xFFFFE7E0),
        iconColor: const Color(0xFFFF6B4A),
        title: '错词本',
        onTap: () => Navigator.pushNamed(context, AppRouter.wrongWord),
        badge: _wrongCount > 0 ? '$_wrongCount' : null,
      ),
      _listItem(
        icon: Icons.palette,
        bg: const Color(0xFFF3EFFF),
        iconColor: const Color(0xFF9B7EE8),
        title: '卡片主题',
        onTap: () =>
            Navigator.pushNamed(context, AppRouter.cardThemeSelect),
      ),
      _listItem(
        icon: Icons.notifications_none,
        bg: colors.amberBg,
        iconColor: const Color(0xFFD4900A),
        title: '学习提醒',
        onTap: () => Navigator.pushNamed(context, AppRouter.studyReminder),
      ),
      _listItem(
        icon: Icons.settings,
        bg: colors.divider,
        iconColor: colors.inkSoft,
        title: '设置',
        subtitle: '声音 · 振动 · 关于',
        onTap: () => Navigator.pushNamed(context, AppRouter.settings),
      ),
    ];

    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      children.add(items[i]);
      if (i < items.length - 1) {
        children.add(Container(height: 1, color: colors.divider));
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Column(children: children),
    );
  }

  Widget _listItem({
    required IconData icon,
    required Color bg,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.ink)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: context.appColors.inkSoft)),
                  ],
                ],
              ),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: context.appColors.amberBg,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(badge,
                    style: const TextStyle(
                        color: Color(0xFFB8860B),
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            Icon(Icons.chevron_right,
                color: context.appColors.inkFaint, size: 20),
          ],
        ),
      ),
    );
  }
}
