import 'package:wordmatch/features/feed/data/datasources/feed_disk_cache.dart';
import 'package:wordmatch/features/feed/data/services/arxiv_service.dart';
import 'package:wordmatch/features/feed/data/services/devto_service.dart';
import 'package:wordmatch/features/feed/data/services/freecodecamp_service.dart';
import 'package:wordmatch/features/feed/data/services/github_service.dart';
import 'package:wordmatch/features/feed/data/services/hackernews_service.dart';
import 'package:wordmatch/features/feed/data/services/producthunt_service.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';

/// 资讯仓库：聚合六个内容源，提供带 TTL 的内存缓存 + 磁盘缓存兜底。
///
/// 各源（及 GitHub 各时间窗）独立缓存；列表刷新（`refresh: true` 或
/// TTL 过期）才会重新请求。网络不可用时回退到磁盘缓存，保证离线仍可阅读。
class FeedRepository {
  FeedRepository({
    DevToService? devToService,
    GithubService? githubService,
    HackerNewsService? hackerNewsService,
    FreeCodeCampService? freeCodeCampService,
    ProductHuntService? productHuntService,
    ArxivService? arxivService,
    FeedDiskCache? diskCache,
  })  : _devToService = devToService ?? DevToService(),
        _githubService = githubService ?? GithubService(),
        _hackerNewsService = hackerNewsService ?? HackerNewsService(),
        _freeCodeCampService = freeCodeCampService ?? FreeCodeCampService(),
        _productHuntService = productHuntService ?? ProductHuntService(),
        _arxivService = arxivService ?? ArxivService(),
        _diskCache = diskCache ?? FeedDiskCache();

  /// 全局单例，供 provider 直接使用
  static final FeedRepository instance = FeedRepository();

  static const Duration _ttl = Duration(minutes: 10);

  final DevToService _devToService;
  final GithubService _githubService;
  final HackerNewsService _hackerNewsService;
  final FreeCodeCampService _freeCodeCampService;
  final ProductHuntService _productHuntService;
  final ArxivService _arxivService;
  final FeedDiskCache _diskCache;

  final Map<String, List<FeedItem>> _cache = {};
  final Map<String, DateTime> _fetchedAt = {};

  /// 缓存键：源 + 子键（GitHub 时间窗，如 'weekly'）
  static String _key(FeedSource source, String subKey) =>
      subKey.isEmpty ? source.name : '${source.name}|$subKey';

  /// 获取资讯列表；[refresh] 为 true 时强制重新请求。
  /// [subKey] 用于区分同一源的不同列表（GitHub 的日/周/月/经典榜）。
  Future<FeedResult> getFeed(
    FeedSource source, {
    String subKey = '',
    bool refresh = false,
  }) async {
    final key = _key(source, subKey);
    final cached = _cache[key];
    final fetchedAt = _fetchedAt[key];
    final fresh = cached != null &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _ttl;
    if (!refresh && fresh) return FeedResult(items: cached);

    try {
      final items = switch (source) {
        FeedSource.devto => await _devToService.fetchFeed(),
        FeedSource.github => await _githubService.fetchFeed(
            range: GithubRange.values.byName(subKey.isEmpty
                ? GithubRange.classic.name
                : subKey),
          ),
        FeedSource.hackernews => await _hackerNewsService.fetchFeed(),
        FeedSource.freecodecamp => await _freeCodeCampService.fetchFeed(),
        FeedSource.producthunt => await _productHuntService.fetchFeed(),
        FeedSource.arxiv => await _arxivService.fetchFeed(),
      };
      _cache[key] = items;
      _fetchedAt[key] = DateTime.now();
      // 落盘到磁盘缓存（后台执行，不阻塞本次返回）
      _diskCache.write(key, items);
      return FeedResult(items: items);
    } catch (e) {
      // 网络不可用：回退到磁盘缓存，让用户仍能看到上次抓取的内容
      final stale = await _diskCache.read(key);
      if (stale != null) return stale;
      rethrow;
    }
  }

  /// 获取文章正文（不做缓存，阅读页每次进入都取最新）
  Future<ArticleContent> getArticle(FeedSource source, String id) {
    return switch (source) {
      FeedSource.devto => _devToService.fetchArticle(id),
      FeedSource.github => _githubService.fetchArticle(id),
      FeedSource.hackernews => _hackerNewsService.fetchArticle(id),
      FeedSource.freecodecamp => _freeCodeCampService.fetchArticle(id),
      FeedSource.producthunt => _productHuntService.fetchArticle(id),
      FeedSource.arxiv => _arxivService.fetchArticle(id),
    };
  }
}
