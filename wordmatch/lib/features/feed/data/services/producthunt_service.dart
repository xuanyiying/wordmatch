import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:wordmatch/core/network/http_client.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';

import 'text_utils.dart';

/// Product Hunt 数据源（官方 GraphQL v2）。
///
/// 需要开发者 token：https://www.producthunt.com/v2/oauth/applications
/// 免费申请（scope 选 public），构建时注入：
/// `flutter build apk --dart-define=PRODUCT_HUNT_TOKEN=xxx`
/// 未配置时该源会给出明确报错提示，不影响其他源。
class ProductHuntService {
  static const String _endpoint = 'https://api.producthunt.com/v2/api/graphql';
  static const String _token =
      String.fromEnvironment('PRODUCT_HUNT_TOKEN');
  static const Duration _timeout = Duration(seconds: 15);

  static bool get isConfigured => _token.isNotEmpty;

  Future<List<FeedItem>> fetchFeed() async {
    _ensureConfigured();
    final data = await _query('''
query {
  posts(first: 20, order: VOTES) {
    edges { node { id name tagline description votesCount website } }
  }
}''');
    final edges = _edges(data, ['posts', 'edges']);
    final result = <FeedItem>[];
    for (final edge in edges) {
      if (edge is! Map<String, dynamic>) continue;
      final node = edge['node'];
      if (node is! Map<String, dynamic>) continue;
      final id = _s(node, 'id');
      if (id.isEmpty) continue;
      result.add(FeedItem(
        id: id,
        source: FeedSource.producthunt,
        title: _s(node, 'name'),
        excerpt: _s(node, 'tagline'),
        author: '',
        publishedAt: '',
        url: _s(node, 'website'),
        extra: {
          'votes': '${(node['votesCount'] as num?)?.toInt() ?? 0}',
          'description': _s(node, 'description'),
        },
      ));
    }
    return result;
  }

  /// 正文 = 产品简介 + 热门评论（英文短文本，适合快读）
  Future<ArticleContent> fetchArticle(String id) async {
    _ensureConfigured();
    final data = await _query('''
query(\$id: ID!) {
  post(id: \$id) {
    name tagline description votesCount website
    comments(first: 10, order: VOTES_COUNT) {
      edges { node { body votesCount } }
    }
  }
}''', variables: {'id': id});
    final post = data['post'];
    if (post is! Map<String, dynamic>) {
      throw Exception('Product Hunt 数据格式异常');
    }
    final md = StringBuffer()
      ..writeln(_s(post, 'tagline'))
      ..writeln()
      ..writeln(FeedText.htmlToMarkdown(_s(post, 'description')))
      ..writeln();
    final edges = _edges(post, ['comments', 'edges']);
    if (edges.isNotEmpty) md.writeln('## 热门评论');
    for (final edge in edges) {
      final node = edge is Map<String, dynamic> ? edge['node'] : null;
      if (node is! Map<String, dynamic>) continue;
      final body = FeedText.htmlToMarkdown(_s(node, 'body'));
      if (body.isEmpty) continue;
      md.writeln('- $body');
    }
    final url = _s(post, 'website');
    if (url.isNotEmpty) md.writeln('---\n官网：$url');
    return ArticleContent(
      id: id,
      source: FeedSource.producthunt,
      title: _s(post, 'name', id),
      markdown: md.toString(),
      url: url,
    );
  }

  static void _ensureConfigured() {
    if (!isConfigured) {
      throw Exception(
          'Product Hunt 需要开发者 token（--dart-define=PRODUCT_HUNT_TOKEN=xxx）');
    }
  }

  static List<dynamic> _edges(Map<String, dynamic> data, List<String> path) {
    dynamic cur = data;
    for (final key in path) {
      if (cur is! Map<String, dynamic>) return const [];
      cur = cur[key];
    }
    return cur is List ? cur : const [];
  }

  static String _s(Map<String, dynamic> json, String key, [String fallback = '']) {
    final v = json[key];
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  Future<Map<String, dynamic>> _query(String query,
      {Map<String, dynamic> variables = const {}}) async {
    final http.Response response;
    try {
      response = await appHttpClient
          .post(Uri.parse(_endpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_token',
              },
              body: json.encode({'query': query, 'variables': variables}))
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('请求超时，请检查网络后重试');
    }
    if (response.statusCode == 401) {
      throw Exception('Product Hunt token 无效或已过期');
    }
    if (response.statusCode != 200) {
      throw Exception('Product Hunt 请求失败（HTTP ${response.statusCode}）');
    }
    final dynamic decoded;
    try {
      decoded = json.decode(response.body);
    } on FormatException {
      throw Exception('Product Hunt 数据解析失败');
    }
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Product Hunt 数据格式异常');
    }
    if (decoded['errors'] is List) {
      throw Exception('Product Hunt 接口错误，请稍后再试');
    }
    return (decoded['data'] as Map<String, dynamic>?) ?? const {};
  }
}
