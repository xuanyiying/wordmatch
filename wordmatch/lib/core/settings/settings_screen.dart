import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordmatch/core/constants/app_colors.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/router/app_router.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/core/theme/font_scale_provider.dart';
import 'package:wordmatch/core/theme/theme_mode_provider.dart';

/// 设置页面
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _kZenMode = 'zen_mode';
  bool _zenMode = true;

  @override
  void initState() {
    super.initState();
    _loadZenMode();
  }

  Future<void> _loadZenMode() async {
    final prefs = await SharedPreferences.getInstance();
    _zenMode = prefs.getBool(_kZenMode) ?? true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 渐变头部
            _buildHeader(context),
            // 内容区
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePaddingH,
                  24,
                  AppSizes.pagePaddingH,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // —— 外观 ——
                    _buildSectionHeader('外观', Icons.palette_outlined),
                    _buildSettingsGroup([
                      _buildFontSizeTile(),
                      _buildThemeModeTile(),
                      ListTile(
                        leading: Icon(Icons.layers_outlined,
                            color: colors.mintDeep),
                        title: Text('主题皮肤',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.ink)),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: context.appColors.inkFaint),
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRouter.themeSettings),
                      ),
                    ]),
                    const SizedBox(height: 22),

                    // —— 学习 ——
                    _buildSectionHeader('学习', Icons.school_outlined),
                    _buildSettingsGroup([
                      _buildZenModeTile(),
                      ListTile(
                        leading: Icon(Icons.insights_rounded,
                            color: colors.mintDeep),
                        title: Text('学习统计',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.ink)),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: context.appColors.inkFaint),
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRouter.stats),
                      ),
                    ]),
                    const SizedBox(height: 22),

                    // —— AI 助手 ——
                    _buildSectionHeader('AI 助手', Icons.auto_awesome_outlined),
                    _buildSettingsGroup([
                      ListTile(
                        leading: Icon(Icons.auto_awesome,
                            color: colors.mintDeep),
                        title: Text('大模型 API 配置',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.ink)),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: context.appColors.inkFaint),
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRouter.aiSettings),
                      ),
                    ]),
                    const SizedBox(height: 22),

                    // —— 法律信息 ——
                    _buildSectionHeader('法律信息', Icons.gavel_outlined),
                    _buildSettingsGroup([
                      _buildLegalTile(
                        icon: Icons.privacy_tip_outlined,
                        title: '隐私政策',
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRouter.privacyPolicy),
                      ),
                      _buildLegalTile(
                        icon: Icons.description_outlined,
                        title: '用户协议',
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRouter.userAgreement),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 渐变头部
  Widget _buildHeader(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: colors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '设置',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  '个性化你的学习体验',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 分组小标题：图标 + 文字，统一二级色 + 字重，作为每个设置分区的引导
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: context.appColors.mintDeep),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.appColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  /// iOS 风格设置组：圆角卡片 + 子项间细分隔线（indent 与 ListTile 文本起始对齐）
  Widget _buildSettingsGroup(List<Widget> tiles) {
    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      children.add(tiles[i]);
      if (i < tiles.length - 1) {
        children.add(Divider(
          height: 1,
          thickness: 0.5,
          indent: 56,
          endIndent: 12,
          color: context.appColors.divider,
        ));
      }
    }
    // 外层 DecoratedBox 只画阴影；内层 Material 提供不透明背景 + ink 画布，
    // 这样 ListTile 的水波纹/点击高亮才能正常渲染（否则会报 "ink splashes may be invisible"）。
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  Widget _buildZenModeTile() {
    return SwitchListTile.adaptive(
      secondary: Icon(Icons.spa_outlined, color: context.appColors.mintDeep),
      title: Text('佛系模式',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.appColors.ink)),
      subtitle: Text(
        '不催你、不逼你、不记单词债。消除多少算多少，偶尔不玩天塌不下来。',
        style: TextStyle(fontSize: 12, color: context.appColors.inkSoft),
      ),
      value: _zenMode,
      activeThumbColor: context.appColors.mintDeep,
      onChanged: (v) async {
        setState(() => _zenMode = v);
        final p = await SharedPreferences.getInstance();
        await p.setBool(_kZenMode, v);
        if (!v && mounted) {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('开启魔鬼监督模式？'),
              content: const Text('这意味着每天会强调任务进度、展示复习待办等信息，准备好了吗？😈'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('算了')),
                TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: context.appColors.mintDeep),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('确定开启')),
              ],
            ),
          );
          if (ok != true && mounted) {
            setState(() => _zenMode = true);
            await p.setBool(_kZenMode, true);
          }
        }
      },
    );
  }

  /// 字体大小调节入口（小/标准/大/特大），全局统一缩放
  Widget _buildFontSizeTile() {
    final level = ref.watch(fontScaleLevelProvider);
    return ListTile(
      leading: Icon(Icons.text_fields_rounded, color: context.appColors.mintDeep),
      title: Text('字体大小',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.appColors.ink)),
      subtitle: Text('全局统一缩放 · 当前「${level.label}」',
          style: TextStyle(fontSize: 12, color: context.appColors.inkSoft)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
      onTap: _showFontSizePicker,
    );
  }

  /// 字体大小选择面板：实时预览，选择后即时生效（全 app 同步缩放）
  void _showFontSizePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // Consumer 让面板随 fontScale 变化重建，预览文字即时反映所选字号
        return Consumer(
          builder: (ctx, ref, _) {
            final level = ref.watch(fontScaleLevelProvider);
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 4),
                    child: Row(
                      children: [
                        Icon(Icons.text_fields_rounded,
                            size: 20, color: ctx.appColors.mintDeep),
                        const SizedBox(width: 8),
                        Text('字体大小',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: ctx.appColors.mintDeep)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('完成'),
                        ),
                      ],
                    ),
                  ),
                  // 实时预览（字号随选择即时变化）
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: ctx.appColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Aa 单词消消乐 · 摸鱼刷词',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: ctx.appColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...FontScaleLevel.values.map((l) {
                    final selected = l == level;
                    return InkWell(
                      onTap: () {
                        ref.read(fontScaleControllerProvider.notifier).set(l);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: ctx.appColors.divider, width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.label,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: ctx.appColors.ink)),
                                  const SizedBox(height: 2),
                                  Text(l.desc,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: ctx.appColors.inkSoft)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked,
                              size: 22,
                              color: selected
                                  ? ctx.appColors.mintDeep
                                  : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 夜间模式入口（跟随系统 / 浅色 / 深色），全局生效
  Widget _buildThemeModeTile() {
    final modeAsync = ref.watch(themeModeControllerProvider);
    final mode = modeAsync.value ?? AppThemeMode.system;
    return ListTile(
      leading: Icon(Icons.dark_mode_outlined, color: context.appColors.mintDeep),
      title: Text('夜间模式',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.appColors.ink)),
      subtitle: Text('当前「${mode.label}」',
          style: TextStyle(fontSize: 12, color: context.appColors.inkSoft)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
      onTap: _showThemeModePicker,
    );
  }

  /// 夜间模式选择面板
  void _showThemeModePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final mode = ref.watch(themeModeControllerProvider).value ??
                AppThemeMode.system;
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 4),
                    child: Row(
                      children: [
                        Icon(Icons.dark_mode_outlined,
                            size: 20, color: context.appColors.mintDeep),
                        const SizedBox(width: 8),
                        Text('夜间模式',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: context.appColors.ink)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('完成'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...AppThemeMode.values.map((m) {
                    final selected = m == mode;
                    return InkWell(
                      onTap: () {
                        ref
                            .read(themeModeControllerProvider.notifier)
                            .set(m);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: context.appColors.divider,
                                width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(m.label,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: context.appColors.ink)),
                            ),
                            Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked,
                              size: 22,
                              color: selected
                                  ? context.appColors.mintDeep
                                  : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 法律信息单项（直接放入设置组，由组卡片提供背景与分隔线）
  Widget _buildLegalTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: context.appColors.inkSoft),
      title: Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.appColors.ink)),
      trailing: const Icon(Icons.chevron_right_rounded,
          size: 20, color: AppColors.disabled),
      onTap: onTap,
    );
  }
}
