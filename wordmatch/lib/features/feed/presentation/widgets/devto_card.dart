import 'package:flutter/material.dart';

import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';
import 'package:wordmatch/features/feed/presentation/widgets/feed_brand.dart';

/// dev.to 文章卡片：封面 + 标题 + 摘要 + #tag 徽章 + 作者·时间。
class DevToCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;

  const DevToCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tag = item.extra['tag'] ?? '';
    final metaParts = [
      if (item.author.isNotEmpty) item.author,
      if (item.publishedAt.isNotEmpty) item.publishedAt,
    ];

    return FeedCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.coverImage != null && item.coverImage!.isNotEmpty)
            Image.network(
              item.coverImage!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
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
                if (tag.isNotEmpty || metaParts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // dev.to 品牌蓝 #tag 徽章
                      if (tag.isNotEmpty) ...[
                        Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: FeedBrand.devtoBlue,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          metaParts.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 11, color: colors.inkFaint),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
