import 'package:flutter/material.dart';

import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';
import 'package:wordmatch/features/feed/presentation/widgets/feed_brand.dart';

/// Product Hunt 卡片：仿官方 App 产品行 —— 标题 + tagline + ▲ upvote 徽章。
class ProductHuntCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;

  const ProductHuntCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FeedCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                      height: 1.3,
                    ),
                  ),
                  if (item.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            // PH 标志性 upvote 徽章：圆角方框内 ▲ + 票数
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: FeedBrand.phOrange, width: 1.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_drop_up,
                      size: 16, color: FeedBrand.phOrange),
                  Text(
                    '${item.extra['votes'] ?? 0}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: FeedBrand.phOrange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
