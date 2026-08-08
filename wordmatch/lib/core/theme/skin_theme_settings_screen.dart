import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/core/subscription/subscription_provider.dart';
import 'package:wordmatch/core/subscription/subscription_tier.dart';
import 'package:wordmatch/core/subscription/upgrade_pro_dialog.dart';
import 'skin_theme.dart';
import 'skin_theme_service.dart';
import 'skin_theme_provider.dart';

class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen> {
  AppThemeKey? _selectedKey;
  AppThemeKey? _initialKey;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final key = await ThemeService.getCurrent();
    if (!mounted) return;
    setState(() {
      _selectedKey = key;
      _initialKey = key;
      _isLoaded = true;
    });
  }

  Future<void> _onThemeTap(AppThemeData theme) async {
    final tierAsync = ref.read(tierProvider);
    final isPro = tierAsync.maybeWhen(
      data: (t) => t.isPro,
      orElse: () => false,
    );

    if (theme.key.isProOnly && !isPro) {
      final ok = await showUpgradeProDialog(context, reason: 'Pro 专享皮肤');
      if (ok == true && mounted) {
        ref.invalidate(tierProvider);
      }
      return;
    }

    await ThemeService.setCurrent(theme.key);
    ref.invalidate(themeProvider);
    setState(() => _selectedKey = theme.key);
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = AppThemes.of(_selectedKey ?? AppThemeKey.academic);

    return Scaffold(
      backgroundColor: currentTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(currentTheme),
            Expanded(
              child: !_isLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.78,
                            children: AppThemes.all
                                .map((t) => _buildThemeCard(t))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                          _buildProTip(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeData currentTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: currentTheme.headerGradient,
        borderRadius: const BorderRadius.only(
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
              onPressed: () {
                final changed = _selectedKey != _initialKey;
                Navigator.of(context).pop(changed);
              },
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
                  '主题皮肤',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  '4 套精美皮肤，个性化你的单词之旅',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(AppThemeData theme) {
    final isSelected = _selectedKey == theme.key;
    final locked = theme.key.isProOnly;

    return Consumer(
      builder: (ctx, ref, _) {
        final tierAsync = ref.watch(tierProvider);
        final isPro = tierAsync.maybeWhen(
          data: (t) => t.isPro,
          orElse: () => false,
        );
        final showLock = locked && !isPro;

        return GestureDetector(
          onTap: () => _onThemeTap(theme),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? theme.primary : Colors.transparent,
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primary.withValues(alpha: isSelected ? 0.18 : 0.06),
                      blurRadius: isSelected ? 16 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [theme.primary, theme.primaryDark],
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: Center(
                        child: Text(
                          theme.key.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: theme.primary,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: theme.accent,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: theme.background,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                        color: Colors.grey.shade300, width: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (showLock)
                              Row(
                                children: [
                                  Icon(Icons.lock_rounded,
                                      size: 13,
                                      color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pro 专享',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              )
                            else if (!locked)
                              Text(
                                '免费',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.primary,
                                    fontWeight: FontWeight.w600),
                              )
                            else
                              Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 13, color: theme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '已解锁',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: theme.primary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              if (showLock)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProTip() {
    return Consumer(
      builder: (ctx, ref, _) {
        final tierAsync = ref.watch(tierProvider);
        final isPro = tierAsync.maybeWhen(
          data: (t) => t.isPro,
          orElse: () => false,
        );
        if (isPro) return const SizedBox.shrink();

        final theme = AppThemes.of(_selectedKey ?? AppThemeKey.academic);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              theme.primary.withValues(alpha: 0.08),
              theme.accent.withValues(alpha: 0.05),
            ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primary, theme.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pro 专享皮肤',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '开通后一键切换全部 4 套皮肤，无广告体验',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
