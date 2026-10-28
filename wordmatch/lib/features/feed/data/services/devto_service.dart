import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:wordmatch/core/network/http_client.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';

/// dev.to 数据源：技术文章列表与正文
class DevToService {
  static const String _baseUrl = 'https://dev.to/api/articles';
  static const Duration _timeout = Duration(seconds: 15);

  /// 并行拉取多个 tag 的文章列表，按文章 id 去重合并。
  ///
  /// 每条记录的 [FeedItem.extra] 携带 `'tag'`（该条来自哪个 tag）。
  Future<List<FeedItem>> fetchFeed({int page = 1}) async {
    const tags = ['webdev', 'dart', 'programming'];
    final responses = await Future.wait([
      for (final tag in tags) _get(Uri.parse('$_baseUrl?tag=$tag&per_page=15&page=$page')),
    ]);

    // 按文章 id 去重：同一文章命中多个 tag 时保留首次出现
    final byId = <String, FeedItem>{};
    for (var i = 0; i < tags.length; i++) {
      final dynamic decoded;
      try {
        decoded = json.decode(responses[i].body);
      } on FormatException {
        continue; // 单个 tag 数据损坏不影响整体
      }
      if (decoded is! List) continue;
      for (final raw in decoded) {
        if (raw is! Map<String, dynamic>) continue;
        final item = _mapArticle(raw, tags[i]);
        if (item.id.isEmpty) continue;
        byId.putIfAbsent(item.id, () => item);
      }
    }
    return byId.values.toList();
  }

  /// 拉取单篇文章正文（body_markdown）
  Future<ArticleContent> fetchArticle(String id) async {
    final response = await _get(Uri.parse('$_baseUrl/$id'));
    final dynamic raw;
    try {
      raw = json.decode(response.body);
    } on FormatException {
      throw Exception('dev.to 文章数据解析失败');
    }
    if (raw is! Map<String, dynamic>) {
      throw Exception('dev.to 文章数据格式异常');
    }
    final user = raw['user'];
    return ArticleContent(
      id: _str(raw, 'id'),
      source: FeedSource.devto,
      title: _str(raw, 'title'),
      markdown: _str(raw, 'body_markdown'),
      url: _str(raw, 'url'),
      author: user is Map<String, dynamic> ? _str(user, 'name') : '',
      publishedAt: _str(raw, 'readable_publish_date'),
    );
  }

  FeedItem _mapArticle(Map<String, dynamic> raw, String tag) {
    final user = raw['user'];
    return FeedItem(
      id: _str(raw, 'id'),
      source: FeedSource.devto,
      title: _str(raw, 'title'),
      excerpt: _str(raw, 'description'),
      author: user is Map<String, dynamic> ? _str(user, 'name') : '',
      publishedAt: _str(raw, 'readable_publish_date'),
      url: _str(raw, 'url'),
      coverImage: raw['cover_image'] is String && (raw['cover_image'] as String).isNotEmpty
          ? raw['cover_image'] as String
          : null,
      extra: {'tag': tag},
    );
  }

  Future<http.Response> _get(Uri uri) async {
    final http.Response response;
    try {
      response = await appHttpClient.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw Exception('请求超时，请检查网络后重试');
    }
    if (response.statusCode != 200) {
      throw Exception('dev.to 请求失败（HTTP ${response.statusCode}）');
    }
    return response;
  }

  /// 字段级容错读取：缺失或类型不符时回退默认值
  static String _str(Map<String, dynamic> json, String key, [String fallback = '']) {
    final v = json[key];
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }
}
