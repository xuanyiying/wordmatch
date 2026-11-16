import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';
import 'package:wordmatch/features/feed/presentation/providers/feed_providers.dart';
import 'package:wordmatch/features/feed/presentation/screens/article_reader_screen.dart';
import 'package:wordmatch/features/feed/presentation/widgets/devto_card.dart';
import 'package:wordmatch/features/feed/presentation/widgets/github_repo_card.dart';
import 'package:wordmatch/features/feed/presentation/widgets/hackernews_card.dart';
import 'package:wordmatch/features/feed/presentation/widgets/producthunt_card.dart';

/// 资讯 Tab 页：热门文章（dev.to）/ 热门仓库（GitHub）
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final source = ref.watch(feedSourceProvider);
    final githubRange = ref.watch(githubRangeProvider);
    final feedAsync = ref.watch(feedListProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 6, 0),
              child: Row(
                children: [
                  Text(
                    '热门资讯',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => ref.invalidate(feedListProvider),
                    icon: const Icon(Icons.refresh),
                    color: colors.inkSoft,
                    tooltip: '刷新',
                  ),
                ],
              ),
            ),
            // 资讯源切换（6 源，横向可滑动）
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // freeCodeCamp 暂不展示入口（RSS 源在部分网络不可用），service 保留
                    for (final s in FeedSource.values
                        .where((s) => s != FeedSource.freecodecamp)) ...[
                      _filterChip(
                        context,
                        s.label,
                        selected: source == s,
                        onTap: () =>
                            ref.read(feedSourceProvider.notifier).set(s),
                      ),
                      if (s != FeedSource.values.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
            // GitHub 源：热门时间窗切换（日/周/月榜 + 经典）
            if (source == FeedSource.github)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: Row(
                  children: [
                    for (final r in GithubRange.values) ...[
                      _filterChip(
                        context,
                        r.label,
                        selected: githubRange == r,
                        onTap: () =>
                            ref.read(githubRangeProvider.notifier).set(r),
                      ),
                      if (r != GithubRange.values.last)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            // 列表
            Expanded(
              child: feedAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _errorView(context, ref, e),
                data: (result) => result.items.isEmpty
                    ? _emptyView(context, ref)
                    : Column(
                        children: [
                          if (result.isStale)
                            _offlineBanner(context, result.updatedAt),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 2, 12, 16),
                              itemCount: result.items.length,
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _itemCard(context, result.items[i]),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 按 source 分发到各源的官方风格卡片
  Widget _itemCard(BuildContext context, FeedItem item) {
    void open() {
      Navigator.pushNamed(
        context,
        '/feed_article',
        arguments: ArticleReaderArgs(
          source: item.source,
          id: item.id,
          extra: item.extra,
        ),
      );
    }
    return switch (item.source) {
      FeedSource.github =>
        GithubRepoCard(item: item, onTap: open),
      FeedSource.hackernews =>
        HackerNewsCard(item: item, onTap: open),
      FeedSource.producthunt =>
        ProductHuntCard(item: item, onTap: open),
      _ => DevToCard(item: item, onTap: open),
    };
  }

  // ============ 筛选 chip（资讯源 / GitHub 时间窗共用） ============

  Widget _filterChip(
    BuildContext context,
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      backgroundColor: colors.card,
      selectedColor: colors.mintBg,
      side: BorderSide(color: selected ? colors.mintDeep : colors.border),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? colors.mintDeep : colors.inkSoft,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  // ============ 异常 / 空态 ============

  Widget _errorView(BuildContext context, WidgetRef ref, Object error) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 36, color: colors.inkFaint),
            const SizedBox(height: 12),
            Text(
              '加载失败，请检查网络后重试',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.inkSoft),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(feedListProvider),
              style: FilledButton.styleFrom(
                backgroundColor: colors.mintDeep,
                foregroundColor: colors.card,
              ),
              child: const Text('重试', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    return Center(
      child: GestureDetector(
        onTap: () => ref.invalidate(feedListProvider),
        child: Text(
          '暂无内容，下拉重试',
          style: TextStyle(fontSize: 13, color: colors.inkFaint),
        ),
      ),
    );
  }

  /// 离线兜底提示条：网络不可用，展示的是磁盘缓存内容
  Widget _offlineBanner(BuildContext context, DateTime? updatedAt) {
    final colors = context.appColors;
    final time = updatedAt == null
        ? ''
        : '（${updatedAt.month}月${updatedAt.day}日 '
            '${updatedAt.hour.toString().padLeft(2, '0')}:'
            '${updatedAt.minute.toString().padLeft(2, '0')}）';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.mintBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 16, color: colors.mintDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '当前离线，显示上次缓存的内容$time',
              style: TextStyle(fontSize: 12, color: colors.mintDeep),
            ),
          ),
        ],
      ),
    );
  }
}
