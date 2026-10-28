/// 资讯频道数据模型
///
/// 内容源：dev.to / GitHub / Hacker News / freeCodeCamp /
/// Product Hunt（需 token）/ arXiv。
/// 各源统一抽象为 [FeedItem] 列表；点开后统一返回
/// [ArticleContent]（markdown 正文），供阅读页做划词标注。
enum FeedSource {
  devto,
  github,
  hackernews,
  freecodecamp,
  producthunt,
  arxiv,
}

/// GitHub 源的热门时间窗。
/// GitHub 无官方 trending API：daily/weekly/monthly 抓取
/// github.com/trending 官方榜单页解析（与网页热榜一致，失败时回退
/// Search API 的 created 时间窗 + star 降序近似）；
/// classic=Search API star 过万的常青仓库。
enum GithubRange { daily, weekly, monthly, classic }

extension GithubRangeX on GithubRange {
  String get label => switch (this) {
        GithubRange.daily => '日榜',
        GithubRange.weekly => '周榜',
        GithubRange.monthly => '月榜',
        GithubRange.classic => '经典',
      };
}

/// 资讯源显示名
extension FeedSourceX on FeedSource {
  String get label => switch (this) {
        FeedSource.devto => 'dev.to',
        FeedSource.github => 'GitHub',
        FeedSource.hackernews => 'Hacker News',
        FeedSource.freecodecamp => 'freeCodeCamp',
        FeedSource.producthunt => 'Product Hunt',
        FeedSource.arxiv => 'arXiv',
      };
}

/// 资讯列表项
class FeedItem {
  /// 源内唯一 id（dev.to 文章 id / GitHub 仓库全名 owner/repo）
  final String id;
  final FeedSource source;
  final String title;

  /// 摘要（dev.to 文章 description / GitHub 仓库 description）
  final String excerpt;
  final String author;
  final String publishedAt;

  /// 原文链接
  final String url;

  /// 封面图（可空）
  final String? coverImage;

  /// 附加展示信息：dev.to → {'tag': 'webdev'}；GitHub → {'stars': '12.3k', 'language': 'Dart'}
  final Map<String, String> extra;

  const FeedItem({
    required this.id,
    required this.source,
    required this.title,
    required this.excerpt,
    this.author = '',
    this.publishedAt = '',
    this.url = '',
    this.coverImage,
    this.extra = const {},
  });

  /// 序列化为 JSON（用于资讯列表的磁盘缓存）
  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source.name,
        'title': title,
        'excerpt': excerpt,
        'author': author,
        'publishedAt': publishedAt,
        'url': url,
        'coverImage': coverImage,
        'extra': extra,
      };

  /// 从 JSON 还原（磁盘缓存读取）。字段缺失或类型不符时回退默认值。
  factory FeedItem.fromJson(Map<String, dynamic> json) {
    final sourceName = json['source'] as String? ?? '';
    final rawExtra = json['extra'];
    return FeedItem(
      id: json['id'] as String? ?? '',
      source: FeedSource.values.firstWhere(
        (s) => s.name == sourceName,
        orElse: () => FeedSource.devto,
      ),
      title: json['title'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      author: json['author'] as String? ?? '',
      publishedAt: json['publishedAt'] as String? ?? '',
      url: json['url'] as String? ?? '',
      coverImage: json['coverImage'] as String?,
      extra: rawExtra is Map
          ? rawExtra.map((k, v) => MapEntry(k.toString(), v.toString()))
          : const {},
    );
  }
}

/// 资讯列表查询结果
class FeedResult {
  /// 列表内容
  final List<FeedItem> items;

  /// 是否为磁盘缓存兜底（网络不可用时展示上次抓取的内容）
  final bool isStale;

  /// 缓存内容的抓取时间（仅 [isStale] 为 true 时有意义）
  final DateTime? updatedAt;

  const FeedResult({
    required this.items,
    this.isStale = false,
    this.updatedAt,
  });
}

/// 文章正文（阅读页输入）
class ArticleContent {
  final String id;
  final FeedSource source;
  final String title;

  /// Markdown 正文（dev.to body_markdown / GitHub README）
  final String markdown;
  final String url;
  final String author;
  final String publishedAt;

  const ArticleContent({
    required this.id,
    required this.source,
    required this.title,
    required this.markdown,
    this.url = '',
    this.author = '',
    this.publishedAt = '',
  });
}
