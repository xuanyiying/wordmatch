import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:wordmatch/core/network/http_client.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';

import 'text_utils.dart';

/// freeCodeCamp 数据源（官方 Ghost RSS，免鉴权）。
///
/// RSS 含 content:encoded 全文 HTML，列表与正文共用一次请求；
/// 全文缓存于内存，fetchArticle 直接复用。
class FreeCodeCampService {
  static const String _feedUrl =
      'https://www.freecodecamp.org/news/rss/';
  static const Duration _timeout = Duration(seconds: 20);

  /// link → {title, text}（fetchFeed 时填充，fetchArticle 复用；text 为纯文本）
  static final Map<String, Map<String, String>> _contentCache = {};

  /// 已缓存的纯文本正文（测试/调试用）
  static String? contentFor(String id) => _contentCache[id]?['text'];

  Future<List<FeedItem>> fetchFeed() async {
    final http.Response response;
    try {
      response = await appHttpClient
          .get(Uri.parse(_feedUrl),
              headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('请求超时，请检查网络后重试');
    }
    if (response.statusCode != 200) {
      throw Exception('freeCodeCamp 请求失败（HTTP ${response.statusCode}）');
    }
    return parseFeed(response.body);
  }

  Future<ArticleContent> fetchArticle(String id) async {
    if (!_contentCache.containsKey(id)) await fetchFeed();
    final cached = _contentCache[id];
    var text = cached?['text'] ?? '';
    if (text.isEmpty) {
      throw Exception('文章内容不存在或已下架');
    }
    if (text.length > 30000) text = '${text.substring(0, 30000)}…';
    return ArticleContent(
      id: id,
      source: FeedSource.freecodecamp,
      title: cached!['title'] ?? id,
      markdown: text,
      url: id,
    );
  }

  static List<FeedItem> parseFeed(String body) {
    final items = FeedXml.blocks(body, 'item');
    final result = <FeedItem>[];
    for (final item in items) {
      final title = FeedXml.field(item, 'title');
      final link = FeedXml.field(item, 'link').trim();
      if (title.isEmpty || link.isEmpty) continue;
      final content = FeedXml.field(item, 'content:encoded');
      if (content.isNotEmpty) {
        _contentCache[link] = {'title': title, 'text': content};
      }
      result.add(FeedItem(
        id: link,
        source: FeedSource.freecodecamp,
        title: title,
        excerpt: FeedXml.field(item, 'description'),
        author: FeedXml.field(item, 'dc:creator'),
        publishedAt: _formatRfc822(FeedXml.field(item, 'pubDate')),
        url: link,
        extra: {'tag': FeedXml.blocks(item, 'category').firstOrNull ?? ''},
      ));
    }
    return result;
  }

  /// RFC822（Thu, 08 Oct 2026 …）→ yyyy-MM-dd，解析失败返回原串前 10 位
  static String _formatRfc822(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.length < 4) return raw;
    const months = {
      'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04', 'May': '05',
      'Jun': '06', 'Jul': '07', 'Aug': '08', 'Sep': '09', 'Oct': '10',
      'Nov': '11', 'Dec': '12',
    };
    final mon = months[parts[2]];
    if (mon == null) return raw;
    return '${parts[3]}-$mon-${parts[1].padLeft(2, '0')}';
  }
}
