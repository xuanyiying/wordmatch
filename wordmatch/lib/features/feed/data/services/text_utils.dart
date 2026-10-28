/// feed 数据源共用的文本/XML 清洗工具。
class FeedText {
  FeedText._();

  /// 解码数值（&#8212; / &#x2014;）与常见命名实体
  static String decodeEntities(String s) {
    var r = s.replaceAllMapped(
        RegExp(r'&#x([0-9a-fA-F]+);'),
        (m) =>
            String.fromCharCode(int.parse(m.group(1)!, radix: 16)));
    r = r.replaceAllMapped(RegExp(r'&#(\d+);'),
        (m) => String.fromCharCode(int.parse(m.group(1)!)));
    const named = {
      'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"', 'apos': "'",
      'nbsp': ' ', 'hellip': '…', 'mdash': '—', 'ndash': '–',
      'rsquo': '’', 'lsquo': '‘', 'rdquo': '”', 'ldquo': '“',
      'middot': '·', 'copy': '©',
    };
    return r.replaceAllMapped(
        RegExp(r'&([a-zA-Z]+);'), (m) => named[m.group(1)!] ?? m.group(0)!);
  }

  /// HTML → 纯文本：块级标签转换行，去其余标签，解码实体，收束空白
  static String htmlToPlainText(String html) {
    // 闭标签与 <br> 转换行
    var r = html.replaceAll(
        RegExp(r'<(br|/p|/div|/h[1-6]|/blockquote)[^>]*>',
            caseSensitive: false),
        '\n');
    // 开标签也转换行（否则相邻段落间只剩单个 \n）
    r = r.replaceAll(
        RegExp(r'<(p|div|h[1-6]|blockquote)[^>]*>', caseSensitive: false),
        '\n');
    // 列表项加圆点
    r = r.replaceAll(
        RegExp(r'<li[^>]*>', caseSensitive: false), '• ');
    r = r.replaceAll(RegExp(r'<[^>]+>'), '');
    r = decodeEntities(r);
    r = r.replaceAll(RegExp(r'[ \t]+'), ' ');
    r = r.replaceAll(RegExp(r'\n '), '\n');
    r = r.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return r.trim();
  }

  /// HTML → Markdown：与 [htmlToPlainText] 同样拍平正文，但代码结构
  /// 保留为 markdown 语法（`<pre>` → 围栏代码块、行内 `<code>` → 反引号），
  /// 使阅读页的 markdown AST 判定对非 markdown 源（HN/PH 评论等）
  /// 也能正确识别代码/命令，不做划词标注。
  static String htmlToMarkdown(String html) {
    // 1. <pre>（常内嵌 <code>/高亮 span）→ 占位保护，避免内部内容被通用清洗破坏
    final codeBlocks = <String>[];
    var r = html.replaceAllMapped(
        RegExp(r'<pre[^>]*>(.*?)</pre>', dotAll: true, caseSensitive: false),
        (m) {
      codeBlocks.add(m.group(1)!.replaceAll(RegExp(r'<[^>]+>'), ''));
      return '\x00CODEBLOCK${codeBlocks.length - 1}\x00';
    });

    // 2. 行内 <code> → 反引号包裹
    r = r.replaceAllMapped(
        RegExp(r'<code[^>]*>(.*?)</code>', dotAll: true, caseSensitive: false),
        (m) => '`${m.group(1)!.replaceAll(RegExp(r'<[^>]+>'), '')}`');

    // 3. 其余块级标签转换行、剥标签、解码实体、收束空白（同 htmlToPlainText）
    r = r.replaceAll(
        RegExp(r'<(br|/p|/div|/h[1-6]|/blockquote)[^>]*>',
            caseSensitive: false),
        '\n');
    r = r.replaceAll(
        RegExp(r'<(p|div|h[1-6]|blockquote)[^>]*>', caseSensitive: false),
        '\n');
    r = r.replaceAll(
        RegExp(r'<li[^>]*>', caseSensitive: false), '• ');
    r = r.replaceAll(RegExp(r'<[^>]+>'), '');
    r = decodeEntities(r);
    r = r.replaceAll(RegExp(r'[ \t]+'), ' ');
    r = r.replaceAll(RegExp(r'\n '), '\n');
    r = r.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 4. 最后还原围栏代码块（内容不再被空白清洗破坏，独立成块供 AST 识别）
    return r.replaceAllMapped(RegExp('\x00CODEBLOCK(\\d+)\x00'), (m) {
      final i = int.parse(m.group(1)!);
      return '\n\n```\n${decodeEntities(codeBlocks[i]).trim()}\n```\n\n';
    }).trim();
  }
}

/// 极简 XML/RSS/Atom 取值工具（feed 源专用，避免引入 XML 依赖）。
class FeedXml {
  FeedXml._();

  static RegExp _tagRe(String tag) =>
      RegExp('<$tag(?:\\s[^>]*)?>(.*?)</$tag>', dotAll: true);

  /// 提取所有 `<tag ...>...</tag>` 块的内部内容（CDATA 已解包）
  static List<String> blocks(String xml, String tag) =>
      _tagRe(tag).allMatches(xml).map((m) => _stripCdata(m.group(1)!)).toList();

  /// 取首个 `<tag>` 的内部文本：CDATA 优先，解码实体并去内嵌标签
  static String field(String xml, String tag) {
    final m = _tagRe(tag).firstMatch(xml);
    if (m == null) return '';
    return FeedText.htmlToPlainText(_stripCdata(m.group(1) ?? ''));
  }

  /// 取标签属性值（如 `<arxiv:primary_category term="cs.CL">`）
  static String? attr(String xml, String tag, String attr) {
    final m = RegExp('<$tag[^>]*\\b$attr="([^"]*)"').firstMatch(xml);
    return m?.group(1);
  }

  static String _stripCdata(String inner) => inner.replaceAllMapped(
      RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true), (m) => m.group(1)!);
}
