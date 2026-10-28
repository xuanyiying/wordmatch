import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:wordmatch/core/network/http_client.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';

import 'text_utils.dart';

/// Hacker News 数据源（Algolia 官方 API，免鉴权）。
///
/// 列表为当前 front page；正文为故事文本（Ask HN）+ 高赞讨论，
/// HN 本身是外链聚合，评论区就是最好的英文阅读材料。
class HackerNewsService {
  static const String _base = 'https://hn.algolia.com/api/v1';
  static const Duration _timeout = Duration(seconds: 15);

  /// 每篇最多收录的评论数 / 单条评论长度上限
  static const int _maxComments = 15;
  static const int _maxCommentChars = 1500;

  Future<List<FeedItem>> fetchFeed() async {
    final response = await _get(
        Uri.parse('$_base/search?tags=front_page&hitsPerPage=30'));
    return parseFeed(response.body);
  }

  /// 拉取故事文本 + 高赞评论，拼成阅读正文
  Future<ArticleContent> fetchArticle(String id) async {
    final response = await _get(Uri.parse('$_base/items/$id'));
    final dynamic decoded;
    try {
      decoded = json.decode(response.body);
    } on FormatException {
      throw Exception('Hacker News 数据解析失败');
    }
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Hacker News 数据格式异常');
    }
    final md = StringBuffer();
    final storyText = _s(decoded, 'text');
    if (storyText.isNotEmpty) {
      md.writeln(FeedText.htmlToMarkdown(storyText));
      md.writeln();
    }
    var count = 0;
    final children = decoded['children'];
    if (children is List) {
      for (final c in children) {
        if (count >= _maxComments) break;
        if (c is! Map<String, dynamic>) continue;
        final text = FeedText.htmlToMarkdown(_s(c, 'text'));
        if (text.length < 40) continue; // 过滤灌水短评
        final author = _s(c, 'author');
        md.writeln(author.isEmpty ? '' : '### @$author');
        md.writeln(text.length > _maxCommentChars
            ? '${text.substring(0, _maxCommentChars)}…'
            : text);
        md.writeln();
        count++;
      }
    }
    final url = _s(decoded, 'url');
    if (url.isNotEmpty) md.writeln('---\n原文链接：$url');
    return ArticleContent(
      id: id,
      source: FeedSource.hackernews,
      title: _s(decoded, 'title', id),
      markdown: md.toString(),
      url: url,
    );
  }

  static List<FeedItem> parseFeed(String body) {
    final dynamic decoded;
    try {
      decoded = json.decode(body);
    } on FormatException {
      throw Exception('Hacker News 数据解析失败');
    }
    final hits = decoded is Map<String, dynamic> ? decoded['hits'] : null;
    if (hits is! List) return const [];
    final result = <FeedItem>[];
    for (final raw in hits) {
      if (raw is! Map<String, dynamic>) continue;
      final id = _s(raw, 'objectID');
      final title = _s(raw, 'title');
      if (id.isEmpty || title.isEmpty) continue;
      result.add(FeedItem(
        id: id,
        source: FeedSource.hackernews,
        title: title,
        excerpt: FeedText.htmlToPlainText(_s(raw, 'story_text')),
        author: _s(raw, 'author'),
        publishedAt: _s(raw, 'created_at').substring(0, 10),
        url: _s(raw, 'url'),
        extra: {
          'points': '${(raw['points'] as num?)?.toInt() ?? 0}',
          'comments': '${(raw['num_comments'] as num?)?.toInt() ?? 0}',
        },
      ));
    }
    return result;
  }

  static String _s(Map<String, dynamic> json, String key, [String fallback = '']) {
    final v = json[key];
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  Future<http.Response> _get(Uri uri) async {
    final http.Response response;
    try {
      response = await appHttpClient.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw Exception('请求超时，请检查网络后重试');
    }
    if (response.statusCode != 200) {
      throw Exception('Hacker News 请求失败（HTTP ${response.statusCode}）');
    }
    return response;
  }
}
