import 'package:flutter/material.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/theme/card_theme.dart';
import 'package:wordmatch/features/game/data/models/game_state.dart';
import 'package:wordmatch/features/game/presentation/widgets/card_widget.dart';

/// 消除网格组件
class GridWidget extends StatelessWidget {
  final GameState gameState;
  final void Function(int index) onCardTap;
  final CardThemeType themeType;

  /// 卡牌 GlobalKey 列表，供外部通过 RenderBox 获取卡牌实际屏幕坐标
  final List<GlobalKey> cardKeys;

  const GridWidget({
    super.key,
    required this.gameState,
    required this.onCardTap,
    required this.cardKeys,
    this.themeType = CardThemeType.academic,
  });

  @override
  Widget build(BuildContext context) {
    // 每行固定 4 个卡片，卡片大小一致；
    // 自适应体现在行数——更多卡片则更多行，而非更多列。
    const gridCols = 4;
    const spacing = AppSizes.gridSpacing;
    const aspectRatio = 1.0;

    final cards = gameState.cards;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePaddingH),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final totalSpacing = spacing * (gridCols - 1);
          final cardWidth = (availableWidth - totalSpacing) / gridCols;
          final cardHeight = cardWidth / aspectRatio;
          // 卡片+间距的步长（用于将网格坐标偏移转为像素偏移）
          final cellStep = cardWidth + spacing;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCols,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              final cardKey =
                  index < cardKeys.length ? cardKeys[index] : null;
              // 只有当卡牌有非零偏移量时才播放滑动动画
              final hasOffset = card.position != Offset.zero;
              if (hasOffset) {
                return TweenAnimationBuilder<Offset>(
                  tween: Tween(begin: card.position, end: Offset.zero),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, offset, child) {
                    final pixelOffset = Offset(
                      offset.dx * cellStep,
                      offset.dy * cellStep,
                    );
                    return Transform.translate(
                      offset: pixelOffset,
                      child: child,
                    );
                  },
                  child: CardWidget(
                    key: cardKey,
                    card: card,
                    width: cardWidth,
                    height: cardHeight,
                    themeType: themeType,
                    onTap: () => onCardTap(index),
                  ),
                );
              }
              return CardWidget(
                key: cardKey,
                card: card,
                width: cardWidth,
                height: cardHeight,
                themeType: themeType,
                onTap: () => onCardTap(index),
              );
            },
          );
        },
      ),
    );
  }
}
