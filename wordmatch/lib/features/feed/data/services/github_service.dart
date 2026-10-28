import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:wordmatch/core/network/http_client.dart';
import 'package:wordmatch/features/feed/data/services/text_utils.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';

/// GitHub 数据源：热门仓库列表与仓库 README
class GithubService {
  static const String _baseUrl = 'https://api.github.com';
  static const Duration _timeout = Duration(seconds: 15);
  static const Map<String, String> _headers = {
    'Accept': 'application/vnd.github+json',
  };
  static const Map<String, String> _htmlHeaders = {
    'Accept': 'text/html',
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
  };

  /// 拉取热门仓库（30 条）。
  ///
  /// [range] 决定时间窗：daily/weekly/monthly 抓取 github.com/trending
  /// 官方榜单页并解析（与网页热榜一致，含"本期 star 增速"），
  /// 抓取或解析失败时回退到 Search API 近似；
  /// classic=star 过万的常青仓库（Search API）。
  Future<List<FeedItem>> fetchFeed(
      {GithubRange range = GithubRange.classic}) async {
    if (range != GithubRange.classic) {
      try {
        final items =
            _applyFilter(await _fetchTrending(range));
        if (items.isNotEmpty) return items;
      } catch (e) {
        // 网页抓取/解析失败 → 回退 Search API 近似
        log('GithubService: 热榜抓取失败，回退 Search API (range=$range)',
            error: e);
      }
    }
    final response = await _get(Uri.parse(
        '$_baseUrl/search/repositories?q=${Uri.encodeQueryComponent(_queryFor(range))}&sort=stars&order=desc&per_page=30'));
    final dynamic decoded;
    try {
      decoded = json.decode(response.body);
    } on FormatException {
      throw Exception('GitHub 数据解析失败');
    }
    final items =
        decoded is Map<String, dynamic> ? decoded['items'] : null;
    if (items is! List) return const [];
    final result = <FeedItem>[];
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final item = _mapRepo(raw);
      if (item.id.isEmpty) continue;
      result.add(item);
    }
    return _applyFilter(result);
  }

  /// 拉取仓库 README（id 即 full_name），正文为原始 Markdown
  Future<ArticleContent> fetchArticle(String id) async {
    final response = await _get(Uri.parse('$_baseUrl/repos/$id/readme'));
    final dynamic decoded;
    try {
      decoded = json.decode(response.body);
    } on FormatException {
      throw Exception('GitHub README 数据解析失败');
    }
    if (decoded is! Map<String, dynamic>) {
      throw Exception('GitHub README 数据格式异常');
    }
    // content 是带换行的 base64，去除换行后解码为 UTF-8 文本
    final content = _str(decoded, 'content').replaceAll('\n', '');
    final markdown = utf8.decode(base64Decode(content));
    return ArticleContent(
      id: id,
      source: FeedSource.github,
      // README 接口响应可能不含 full_name，回退到传入的 id（即 full_name）
      title: _str(decoded, 'full_name', id),
      markdown: markdown,
      url: _str(decoded, 'html_url'),
    );
  }

  /// 时间窗对应的搜索条件
  static String _queryFor(GithubRange range) {
    final days = switch (range) {
      GithubRange.daily => 1,
      GithubRange.weekly => 7,
      GithubRange.monthly => 30,
      GithubRange.classic => 0,
    };
    if (days == 0) return 'stars:>10000';
    final since = DateTime.now().subtract(Duration(days: days));
    final d =
        '${since.year}-${since.month.toString().padLeft(2, '0')}-${since.day.toString().padLeft(2, '0')}';
    // 有 star 的近窗新仓库，按 star 降序即"近期热门"
    return 'created:>=$d stars:>0';
  }

  // ============ trending 官方榜单页抓取（daily/weekly/monthly） ============

  static const Map<GithubRange, String> _sinceParams = {
    GithubRange.daily: 'daily',
    GithubRange.weekly: 'weekly',
    GithubRange.monthly: 'monthly',
  };

  /// 抓取 github.com/trending 榜单页（与网页热榜同一数据）
  Future<List<FeedItem>> _fetchTrending(GithubRange range) async {
    final response = await _get(
      Uri.parse('https://github.com/trending?since=${_sinceParams[range]}'),
      headers: _htmlHeaders,
    );
    return parseTrending(response.body);
  }

  /// 解析 trending 页 HTML：每个仓库一个 `<article class="Box-row">`。
  ///
  /// 宽松提取（GitHub 改版时字段缺失留空，不抛异常）；
  /// 一个仓库都解析不出时返回空列表，由调用方回退 Search API。
  static List<FeedItem> parseTrending(String html) {
    final chunks = html.split(RegExp(r'<article[^>]*Box-row[^>]*>'));
    final items = <FeedItem>[];
    for (final chunk in chunks.skip(1)) {
      final end = chunk.indexOf('</article>');
      final body = end < 0 ? chunk : chunk.substring(0, end);
      // 仓库链接：href 恰为两段路径（排除 /stargazers、/forks 等子路径）
      final link = RegExp(r'href="/([A-Za-z0-9_.\-]+)/([A-Za-z0-9_.\-]+)"')
          .firstMatch(body);
      if (link == null) continue;
      final fullName = '${link.group(1)}/${link.group(2)}';
      final descMatch =
          RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true).firstMatch(body);
      final langMatch =
          RegExp(r'itemprop="programmingLanguage">([^<]+)<').firstMatch(body);
      final periodMatch = RegExp(
              r'([\d,]+)\s*stars\s*(?:this\s*(week|month)|today)')
          .firstMatch(body);
      items.add(FeedItem(
        id: fullName,
        source: FeedSource.github,
        title: fullName,
        excerpt:
            descMatch == null ? '' : FeedText.htmlToPlainText(descMatch.group(1)!),
        author: link.group(1)!,
        url: 'https://github.com/$fullName',
        extra: {
          'stars': _formatStars(_numAfter(body, '/stargazers"')),
          if (langMatch != null) 'language': langMatch.group(1)!.trim(),
          if (periodMatch != null)
            'starsPeriod':
                '+${_formatStars(int.parse(periodMatch.group(1)!.replaceAll(',', '')))} ${_periodLabel(periodMatch.group(2))}',
        },
      ));
    }
    return items;
  }

  /// "1,234 stars this week / today" 的时间窗 → 中文标签
  static String _periodLabel(String? unit) => switch (unit) {
        'week' => '本周',
        'month' => '本月',
        _ => '今日',
      };

  /// 取 [marker] 首次出现到其后 `</a>` 之间的最后一个数字（去千分位）。
  ///
  /// stargazers 链接内的 svg 图标路径也含数字，取末尾才是 star 数。
  static int _numAfter(String body, String marker) {
    final start = body.indexOf(marker);
    if (start < 0) return 0;
    final end = body.indexOf('</a>', start);
    final seg = body.substring(start, end < 0 ? body.length : end);
    final matches = RegExp(r'\d[\d,]*').allMatches(seg).toList();
    if (matches.isEmpty) return 0;
    return int.parse(matches.last.group(0)!.replaceAll(',', ''));
  }

  /// 过滤中文仓库（标题/描述含中文，目标用户为英文学习者）
  static List<FeedItem> _applyFilter(List<FeedItem> items) => items
      .where((item) => !_containsChinese('${item.title} ${item.excerpt}'))
      .toList();

  FeedItem _mapRepo(Map<String, dynamic> raw) {
    final owner = raw['owner'];
    final stars = (raw['stargazers_count'] as num?)?.toInt() ?? 0;
    final fullName = _str(raw, 'full_name');
    return FeedItem(
      id: fullName,
      source: FeedSource.github,
      title: fullName,
      excerpt: _str(raw, 'description'),
      author: owner is Map<String, dynamic> ? _str(owner, 'login') : '',
      publishedAt: '',
      url: _str(raw, 'html_url'),
      extra: {
        'stars': _formatStars(stars),
        'language': _str(raw, 'language'),
      },
    );
  }

  Future<http.Response> _get(Uri uri, {Map<String, String>? headers}) async {
    final http.Response response;
    try {
      response =
          await appHttpClient
              .get(uri, headers: headers ?? _headers)
              .timeout(_timeout);
    } on TimeoutException {
      throw Exception('请求超时，请检查网络后重试');
    }
    if (response.statusCode == 403 || response.statusCode == 429) {
      throw Exception('GitHub API 限流，请稍后再试');
    }
    if (response.statusCode != 200) {
      throw Exception('GitHub 请求失败（HTTP ${response.statusCode}）');
    }
    return response;
  }

  /// 是否含中文（CJK 统一表意文字，含扩展 A）
  static final RegExp _cjkRe = RegExp(r'[\u3400-\u4dbf\u4e00-\u9fff]');

  static bool _containsChinese(String s) => _cjkRe.hasMatch(s);

  /// star 数格式化：1234 → '1.2k'，12000 → '12k'，999 → '999'
  static String _formatStars(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      final text = k >= 100 ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
      return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}k';
    }
    return '$count';
  }

  /// 字段级容错读取：缺失或类型不符时回退默认值
  static String _str(Map<String, dynamic> json, String key, [String fallback = '']) {
    final v = json[key];
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }
}
