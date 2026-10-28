import 'package:flutter_test/flutter_test.dart';
import 'package:wordmatch/features/feed/data/services/arxiv_service.dart';
import 'package:wordmatch/features/feed/data/services/freecodecamp_service.dart';
import 'package:wordmatch/features/feed/data/services/github_service.dart';
import 'package:wordmatch/features/feed/data/services/hackernews_service.dart';
import 'package:wordmatch/features/feed/data/services/text_utils.dart';

void main() {
  group('FeedText', () {
    test('htmlToPlainText 解码实体并转换行', () {
      expect(
        FeedText.htmlToPlainText(
            '<p>Hello &#8212; world&#x2026;</p><p>Second&nbsp;line</p>'),
        'Hello — world…\n\nSecond line',
      );
    });

    test('htmlToPlainText 去内联标签并收束空白', () {
      expect(
        FeedText.htmlToPlainText('<p>a <b>bold</b>   word</p>'),
        'a bold word',
      );
    });
  });

  group('FeedXml', () {
    test('field 支持 CDATA 与实体', () {
      const xml = '<item><title><![CDATA[Learn &#8220;Dart&#8221; fast]]></title></item>';
      expect(FeedXml.field(xml, 'title'), 'Learn “Dart” fast');
    });

    test('blocks 提取多个同名块', () {
      const xml = '<a><name>x</name></a><a><name>y</name></a>';
      expect(FeedXml.blocks(xml, 'a'), hasLength(2));
    });

    test('attr 读取带命名空间的标签属性', () {
      const xml = '<arxiv:primary_category term="cs.CL" />';
      expect(FeedXml.attr(xml, 'arxiv:primary_category', 'term'), 'cs.CL');
    });
  });

  group('HackerNewsService.parseFeed', () {
    test('映射 hits 字段并过滤无标题项', () {
      const body = '{"hits":['
          '{"objectID":"123","title":"A story","points":100,"num_comments":42,'
          '"author":"alice","created_at":"2026-10-08T10:00:00Z","url":"https://x.dev/a"},'
          '{"objectID":"456","title":null,"points":1}'
          ']}';
      final items = HackerNewsService.parseFeed(body);
      expect(items, hasLength(1));
      expect(items.first.id, '123');
      expect(items.first.title, 'A story');
      expect(items.first.extra['points'], '100');
      expect(items.first.extra['comments'], '42');
      expect(items.first.publishedAt, '2026-10-08');
    });
  });

  group('ArxivService.parseFeed', () {
    test('解析 Atom entry：id 截取/作者截断/分类', () {
      const body = '<feed><entry>'
          '<id>http://arxiv.org/abs/2610.10536v1</id>'
          '<title>Decoupling\n  Exploration</title>'
          '<summary>An abstract about RLVR.</summary>'
          '<published>2026-10-07T17:59:26Z</published>'
          '<arxiv:primary_category term="cs.CL" />'
          '<author><name>A. One</name></author>'
          '<author><name>B. Two</name></author>'
          '<author><name>C. Three</name></author>'
          '<author><name>D. Four</name></author>'
          '</entry></feed>';
      final items = ArxivService.parseFeed(body);
      expect(items, hasLength(1));
      expect(items.first.id, '2610.10536v1');
      expect(items.first.title, 'Decoupling Exploration');
      expect(items.first.author, 'A. One, B. Two, C. Three et al.');
      expect(items.first.extra['tag'], 'cs.CL');
      expect(items.first.publishedAt, '2026-10-07');
    });
  });

  group('FreeCodeCampService.parseFeed', () {
    test('解析 RSS item 并缓存全文', () {
      const body = '<rss><channel><item>'
          '<title><![CDATA[How to Learn React]]></title>'
          '<link><![CDATA[https://www.freecodecamp.org/news/react/]]></link>'
          '<description><![CDATA[A guide.]]></description>'
          '<dc:creator><![CDATA[Jane Doe]]></dc:creator>'
          '<pubDate>Thu, 08 Oct 2026 12:00:00 GMT</pubDate>'
          '<category><![CDATA[React]]></category>'
          '<content:encoded><![CDATA[<p>Full article body</p>]]></content:encoded>'
          '</item></channel></rss>';
      final items = FreeCodeCampService.parseFeed(body);
      expect(items, hasLength(1));
      expect(items.first.title, 'How to Learn React');
      expect(items.first.author, 'Jane Doe');
      expect(items.first.publishedAt, '2026-10-08');
      expect(items.first.extra['tag'], 'React');
      expect(FreeCodeCampService.contentFor(items.first.id), 'Full article body');
    });
  });

  group('GithubService.parseTrending', () {
    const html = '''
<html><body>
<article class="Box-row">
  <h2 class="h3 lh-condensed">
    <a href="/flutter/flutter" class="d-inline-block">flutter / flutter</a>
  </h2>
  <p class="col-9 color-fg-muted my-1 pr-4">
    SDK for apps &amp; UI
  </p>
  <div class="f6 color-fg-muted mt-2">
    <span itemprop="programmingLanguage">Dart</span>
    <a href="/flutter/flutter/stargazers" class="Link--muted d-inline-block mr-3">
      <svg><path d="M8 .25a.75.75 0 0 1 .673.418"></path></svg>
      170,234
    </a>
    <a href="/flutter/flutter/forks" class="Link--muted d-inline-block mr-3">
      <svg></svg>28,000
    </a>
    <span class="d-inline-block float-sm-right">
      <svg></svg>1,234 stars this week
    </span>
  </div>
</article>
<article class="Box-row">
  <h2><a href="/zlib/minizip" class="d-inline-block">zlib / minizip</a></h2>
  <span class="d-inline-block float-sm-right">321 stars today</span>
</article>
</body></html>
''';

    test('解析仓库链接/描述/语言/star 与周期增速', () {
      final items = GithubService.parseTrending(html);
      expect(items, hasLength(2));

      final first = items.first;
      expect(first.id, 'flutter/flutter');
      expect(first.title, 'flutter/flutter');
      expect(first.author, 'flutter');
      expect(first.excerpt, 'SDK for apps & UI');
      expect(first.url, 'https://github.com/flutter/flutter');
      expect(first.extra['language'], 'Dart');
      // svg 图标内的数字不干扰，取链接末尾的 star 数
      expect(first.extra['stars'], '170k');
      expect(first.extra['starsPeriod'], '+1.2k 本周');
    });

    test('字段缺失时留空，today 映射为今日', () {
      final items = GithubService.parseTrending(html);
      final second = items.last;
      expect(second.id, 'zlib/minizip');
      expect(second.excerpt, isEmpty);
      expect(second.extra.containsKey('language'), isFalse);
      expect(second.extra['starsPeriod'], '+321 今日');
    });

    test('无 Box-row 时返回空列表', () {
      expect(GithubService.parseTrending('<html><body>hi</body></html>'),
          isEmpty);
    });
  });
}
