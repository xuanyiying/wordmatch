import 'package:flutter/material.dart';

import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';
import 'package:wordmatch/features/feed/presentation/widgets/feed_brand.dart';

/// Hacker News 卡片：仿官方风格 —— 标题 + 域名 + ▲ points · comments。
class HackerNewsCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;

  const HackerNewsCard({super.key, required this.item, required this.onTap});

  String get _domain {
    try {
      final host = Uri.parse(item.url).host;
      return host.startsWith('www.') ? host.substring(4) : host;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final domain = _domain;

    return FeedCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_drop_up, size: 22, color: FeedBrand.hnOrange),
                const SizedBox(width: 2),
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
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                          height: 1.3,
                        ),
                      ),
                      if (domain.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          domain,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.inkFaint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                '${item.extra['points'] ?? 0} points · '
                '${item.extra['comments'] ?? 0} comments',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: colors.inkFaint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
