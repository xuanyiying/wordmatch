import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/features/feed/data/repositories/feed_repository.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';

/// 当前选中的资讯源 Notifier
class FeedSourceNotifier extends Notifier<FeedSource> {
  @override
  FeedSource build() => FeedSource.devto;

  /// 切换资讯源
  void set(FeedSource source) {
    state = source;
  }
}

/// 当前选中的资讯源
final feedSourceProvider =
    NotifierProvider<FeedSourceNotifier, FeedSource>(FeedSourceNotifier.new);

/// GitHub 源的热门时间窗 Notifier（默认周榜：质量最稳）
class GithubRangeNotifier extends Notifier<GithubRange> {
  @override
  GithubRange build() => GithubRange.weekly;

  void set(GithubRange range) => state = range;
}

/// GitHub 源的热门时间窗
final githubRangeProvider =
    NotifierProvider<GithubRangeNotifier, GithubRange>(GithubRangeNotifier.new);

/// 当前资讯源的列表（依赖源与 GitHub 时间窗；切换时自动重新加载）。
///
/// 刷新：直接 `ref.invalidate(feedListProvider)`。
///
/// 网络不可用时返回磁盘缓存兜底内容（[FeedResult.isStale] 为 true）。
final feedListProvider = FutureProvider<FeedResult>((ref) async {
  final source = ref.watch(feedSourceProvider);
  final range = ref.watch(githubRangeProvider);
  return FeedRepository.instance.getFeed(
    source,
    subKey: source == FeedSource.github ? range.name : '',
  );
});
