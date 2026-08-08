import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/core/constants/app_colors.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/core/theme/card_theme.dart';
import 'package:wordmatch/core/theme/card_theme_providers.dart';
import 'package:wordmatch/core/theme/card_theme_registry.dart';
import 'package:wordmatch/features/game/data/models/game_card.dart';
import 'package:wordmatch/features/game/presentation/widgets/card_widget.dart';

/// 卡片主题选择屏幕：3 套主题横向对比 + 一键应用
class CardThemeSelectScreen extends ConsumerWidget {
  const CardThemeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(cardThemeTypeProvider);
    final themes = CardThemeRegistry.all;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('选择卡片主题')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePaddingH),
        children: [
          Text(
            '选择一套你喜欢的卡片主题，应用全局生效',
            style: TextStyle(color: colors.inkSoft, fontSize: 13),
          ),
          const SizedBox(height: 16),
          for (final t in themes) ...[
            _buildThemeCard(context, ref, t, isCurrent: t.type == current),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    WidgetRef ref,
    CardVisualTheme t, {
    required bool isCurrent,
  }) {
    final colors = context.appColors;
    return Card(
      child: InkWell(
        onTap: () => ref.read(cardThemeControllerProvider.notifier).set(t.type),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.mintDeep.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(t.tag,
                        style: TextStyle(
                            color: colors.mintDeep,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Text(t.label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('当前',
                          style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(t.description,
                  style: TextStyle(
                      color: colors.inkSoft, fontSize: 12)),
              const SizedBox(height: 12),
              // 缩略预览：1 张 typeA + 1 张 typeB 卡片
              SizedBox(
                height: 96,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CardWidget(
                      card: GameCard.typeA(
                        itemId: 'preview_en',
                        text: 'abandon',
                        phonetic: '/əˈbændən/',
                      ),
                      width: 80,
                      height: 80,
                      themeType: t.type,
                    ),
                    const SizedBox(width: 16),
                    CardWidget(
                      card: GameCard.typeB(
                        itemId: 'preview_cn',
                        text: '放弃；抛弃',
                      ),
                      width: 80,
                      height: 80,
                      themeType: t.type,
                    ),
                    const SizedBox(width: 16),
                    CardWidget(
                      card: GameCard.typeA(
                        itemId: 'preview_en2',
                        text: 'abandon',
                      ).copyWith(state: CardState.selected),
                      width: 80,
                      height: 80,
                      themeType: t.type,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
