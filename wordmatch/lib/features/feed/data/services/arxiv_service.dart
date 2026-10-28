import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:wordmatch/core/network/http_client.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';

import 'text_utils.dart';

/// arXiv 数据源（官方 Atom API，免鉴权）。
///
/// 列表为 cs.AI / cs.CL / cs.LG 最新提交（学术英语阅读材料）；
/// 正文 = 标题 + 作者 + 摘要（abstract 本身就是完整阅读段落）。
class ArxivService {
  static const String _base = 'https://export.arxiv.org/api/query';
  static const Duration _timeout = Duration(seconds: 20);

  Future<List<FeedItem>> fetchFeed() async {
    final response = await _get(Uri.parse('$_base'
        '?search_query=cat:cs.AI+OR+cat:cs.CL+OR+cat:cs.LG'
        '&sortBy=submittedDate&sortOrder=descending&max_results=30'));
    return parseFeed(response.body);
  }

  Future<ArticleContent> fetchArticle(String id) async {
    final response = await _get(Uri.parse('$_base?id_list=$id'));
    final entries = FeedXml.blocks(response.body, 'entry');
    if (entries.isEmpty) throw Exception('论文不存在或已被撤回');
    final entry = entries.first;
    final authors = FeedXml.blocks(entry, 'author')
        .map((a) => FeedXml.field(a, 'name'))
        .where((n) => n.isNotEmpty)
        .toList();
    final md = StringBuffer()
      ..writeln(authors.join(', '))
      ..writeln()
      ..writeln(FeedXml.field(entry, 'summary'))
      ..writeln()
      ..writeln('---\n原文链接：https://arxiv.org/abs/$id');
    return ArticleContent(
      id: id,
      source: FeedSource.arxiv,
      title: FeedXml.field(entry, 'title'),
      markdown: md.toString(),
      url: 'https://arxiv.org/abs/$id',
    );
  }

  static List<FeedItem> parseFeed(String body) {
    final result = <FeedItem>[];
    for (final entry in FeedXml.blocks(body, 'entry')) {
      final rawId = FeedXml.field(entry, 'id'); // http://arxiv.org/abs/xxx
      final id = rawId.split('/').last.trim();
      final title = FeedXml.field(entry, 'title').replaceAll(RegExp(r'\s+'), ' ');
      if (id.isEmpty || title.isEmpty) continue;
      final authors = FeedXml.blocks(entry, 'author')
          .map((a) => FeedXml.field(a, 'name'))
          .where((n) => n.isNotEmpty)
          .toList();
      final display = authors.isEmpty
          ? ''
          : authors.length <= 3
              ? authors.join(', ')
              : '${authors.take(3).join(', ')} et al.';
      result.add(FeedItem(
        id: id,
        source: FeedSource.arxiv,
        title: title,
        excerpt: FeedXml.field(entry, 'summary'),
        author: display,
        publishedAt:
            FeedXml.field(entry, 'published').substring(0, 10),
        url: 'https://arxiv.org/abs/$id',
        extra: {
          'tag': FeedXml.attr(entry, 'arxiv:primary_category', 'term') ?? '',
        },
      ));
    }
    return result;
  }

  Future<http.Response> _get(Uri uri) async {
    final http.Response response;
    try {
      response = await appHttpClient.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw Exception('请求超时，请检查网络后重试');
    }
    if (response.statusCode != 200) {
      throw Exception('arXiv 请求失败（HTTP ${response.statusCode}）');
    }
    return response;
  }
}
