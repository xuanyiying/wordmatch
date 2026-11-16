import 'package:flutter/material.dart';

import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';
import 'package:wordmatch/features/feed/presentation/widgets/feed_brand.dart';

/// GitHub 仓库卡片：仿 GitHub 官方 App 仓库行样式。
///
/// repo 图标 + owner/repo 名（链接蓝）→ 描述 →
/// 语言色点 · star · fork · 周期 star 增速。
class GithubRepoCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;

  const GithubRepoCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final link = FeedBrand.githubLink(Theme.of(context).brightness);

    // id 即 full_name（owner/repo）
    final (:owner, :repo) = FeedBrand.parseRepoId(
      item.id,
      fallbackOwner: item.author,
      fallbackRepo: item.title,
    );
    final metaStyle = TextStyle(fontSize: 12, color: colors.inkSoft);

    return FeedCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.book_outlined, size: 15, color: link),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (owner.isNotEmpty)
                          TextSpan(
                            text: '$owner / ',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.inkSoft,
                            ),
                          ),
                        TextSpan(
                          text: repo,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: link,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
            const SizedBox(height: 10),
            // meta 行：语言色点 · star · fork · 周期增速。
            // 用 Wrap 代替 Row + Spacer，窄屏或大字号下自动换行，避免溢出。
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if ((item.extra['language'] ?? '').isNotEmpty)
                  LanguageDot(
                    item.extra['language']!,
                    fallback: colors.inkFaint,
                    textStyle: metaStyle,
                  ),
                if ((item.extra['stars'] ?? '').isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_border, size: 14, color: colors.inkSoft),
                      const SizedBox(width: 3),
                      Text(item.extra['stars']!, style: metaStyle),
                    ],
                  ),
                if ((item.extra['forks'] ?? '').isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_tree_outlined,
                        size: 13,
                        color: colors.inkSoft,
                      ),
                      const SizedBox(width: 3),
                      Text(item.extra['forks']!, style: metaStyle),
                    ],
                  ),
                if ((item.extra['starsPeriod'] ?? '').isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 13, color: colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        item.extra['starsPeriod']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.amber,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
