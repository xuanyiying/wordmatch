import 'package:markdown/markdown.dart' as md;

/// 阅读页 markdown 解析结果。
class ParsedArticle {
  /// 渲染块（按原文顺序）；[ReaderBlock.sections] 为空表示该块含不支持
  /// 的结构，调用方用 MarkdownBody 渲染原始 markdown。
  final List<ReaderBlock> blocks;

  /// 全部 prose 段落纯文本（序号即 proseIndex，含列表项、引用段落）
  final List<String> prose;

  /// 各 prose 段落的行内代码区间（序号与 [prose] 对齐）
  final List<List<({int start, int end})>> codeRanges;

  const ParsedArticle({
    required this.blocks,
    required this.prose,
    required this.codeRanges,
  });
}

class ReaderBlock {
  final String raw;
  final List<ReaderSection> sections;

  const ReaderBlock.fallback(this.raw) : sections = const [];
  const ReaderBlock.rendered(this.raw, this.sections);
}

/// 块内渲染单元
sealed class ReaderSection {
  const ReaderSection();
}

/// 可划词标注的文本段落
class ReaderProse extends ReaderSection {
  final int proseIndex;
  const ReaderProse(this.proseIndex);
}

class ReaderHeading extends ReaderSection {
  final int level;
  final String text;
  const ReaderHeading(this.level, this.text);
}

class ReaderHr extends ReaderSection {
  const ReaderHr();
}

class ReaderQuote extends ReaderSection {
  final List<ReaderSection> children;
  const ReaderQuote(this.children);
}

class ReaderList extends ReaderSection {
  final bool ordered;
  final List<ReaderListItem> items;
  const ReaderList({required this.ordered, required this.items});
}

class ReaderListItem {
  final List<ReaderSection> blocks;
  const ReaderListItem(this.blocks);
}

/// 把文章 markdown 解析成「标注渲染块 + prose 段落表」。
///
/// 整篇文档一次性交给 markdown 解析（不能先按空行切块：松散列表、
/// 多段列表项、引用内多段、含空行的围栏代码块都依赖跨行上下文，
/// 切块会把它们切碎导致列表项丢失或退回错误）。同时复刻
/// `BlockParser.parseLines` 的驱动循环，借 Line 身份索引记录每个
/// 顶层节点消耗的源文行区间，不支持的节点用其原始 markdown 片段
/// 整块退回 MarkdownBody。
class ArticleMarkdownParser {
  /// li 内遇到这些标签视为块级节点：先冲刷行内文本缓冲再递归转换
  static const _blockTags = {
    'p', 'pre', 'blockquote', 'ul', 'ol', 'table',
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr',
  };

  static final RegExp _setextH1Re = RegExp(r'^=+\s*$');
  static final RegExp _setextH2Re = RegExp(r'^-+\s*$');
  static final RegExp _notParaStartRe = RegExp(r'^\s*(#|[-*+>]\s|\d+[.)]\s)');

  static bool _hasLetter(String s) => RegExp(r'[A-Za-z]').hasMatch(s);

  /// 后代中是否存在指定标签（如 img：含图片的段落必须保留 MarkdownBody，
  /// 否则纯文本渲染会退化成 alt 文本）
  static bool _containsTag(md.Element root, String tag) {
    bool walk(List<md.Node>? nodes) {
      for (final n in nodes ?? const <md.Node>[]) {
        if (n is md.Element && (n.tag == tag || walk(n.children))) {
          return true;
        }
      }
      return false;
    }

    return walk(root.children);
  }

  /// 由 inline 子节点拼接纯文本，并记录行内代码区间
  /// （区间内的词不做标注）。em/strong/链接等标记符号随 AST 剥离。
  static (String, List<({int start, int end})>) _plainFromInline(
      List<md.Node>? nodes) {
    final buf = StringBuffer();
    final codeRanges = <({int start, int end})>[];
    void walk(List<md.Node>? children) {
      for (final n in children ?? const <md.Node>[]) {
        if (n is md.Text) {
          // 列表项缩进/被吸收的相邻行在 AST 文本里残留的换行按空格处理
          buf.write(n.text.replaceAll('\n', ' '));
        } else if (n is md.Element) {
          if (n.tag == 'code') {
            final start = buf.length;
            buf.write(n.textContent);
            codeRanges.add((start: start, end: buf.length));
          } else {
            walk(n.children);
          }
        }
      }
    }

    walk(nodes);
    return (buf.toString(), codeRanges);
  }

  static ParsedArticle parse(String markdown) {
    final blocks = <ReaderBlock>[];
    final prose = <String>[];
    final proseCodeRanges = <List<({int start, int end})>>[];

    int addProse(String plain, List<({int start, int end})> ranges) {
      final idx = prose.length;
      prose.add(plain);
      proseCodeRanges.add(ranges);
      return idx;
    }

    final lines = _normalizeSetext(markdown.split('\n'))
        .map(md.Line.new)
        .toList(growable: false);
    final doc = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);
    final parser = md.BlockParser(lines, doc);

    // BlockParser 的当前位置（_pos）是私有的，用 Line 身份反查行号。
    final posOf = <md.Line, int>{
      for (var i = 0; i < lines.length; i++) lines[i]: i,
    };

    // 复刻 BlockParser.parseLines 的驱动循环，为每个产出的顶层节点
    // 记录其源文行区间，作为退回 MarkdownBody 的原始片段。
    final rawNodes = <(md.Node, String)>[];
    md.BlockSyntax? neverMatch;
    var iterationsWithoutProgress = 0;
    while (!parser.isDone) {
      final positionBefore = posOf[parser.current]!;
      for (final syntax in parser.blockSyntaxes) {
        if (syntax == neverMatch) continue;
        if (!syntax.canParse(parser)) continue;

        final node = syntax.parse(parser);
        final positionAfter =
            parser.isDone ? lines.length : posOf[parser.current]!;
        if (node != null) {
          final raw = lines
              .sublist(positionBefore, positionAfter)
              .map((l) => l.content)
              .join('\n');
          rawNodes.add((node, raw));
        }
        neverMatch = positionAfter != positionBefore ? null : syntax;
        break;
      }
      if (parser.isDone) break;
      if (posOf[parser.current]! == positionBefore) {
        if (++iterationsWithoutProgress > 2) {
          throw StateError('ArticleMarkdownParser: block parsing stalled');
        }
      } else {
        iterationsWithoutProgress = 0;
      }
    }

    // Document.parseLineList 在块解析后会私自行内解析 UnparsedContent；
    // 这里自行驱动块解析，需用公开 API 补上同一步骤。
    _parseInlineContent(doc, rawNodes.map((e) => e.$1).toList());

    for (final entry in rawNodes) {
      final section = _sectionFromNode(entry.$1, addProse);
      blocks.add(section == null
          ? ReaderBlock.fallback(entry.$2)
          : ReaderBlock.rendered(entry.$2, [section]));
    }

    return ParsedArticle(
      blocks: blocks,
      prose: prose,
      codeRanges: proseCodeRanges,
    );
  }

  /// 复刻 Document._parseInlineContent：把块解析遗留的
  /// UnparsedContent 替换成行内 AST（strong/link/code 等）。
  static void _parseInlineContent(md.Document doc, List<md.Node> nodes) {
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node is md.UnparsedContent) {
        final inlineNodes = doc.parseInline(node.textContent);
        nodes.removeAt(i);
        nodes.insertAll(i, inlineNodes);
        i += inlineNodes.length - 1;
      } else if (node is md.Element && node.children != null) {
        _parseInlineContent(doc, node.children!);
      }
    }
  }

  /// setext 下划线标题（`Title\n=====`）依赖 BlockParser 的私有 `_start`
  /// 状态，自行驱动块解析时无法复刻；预先改写为 ATX 标题，语义等价。
  static List<String> _normalizeSetext(List<String> lines) {
    for (var i = 0; i + 1 < lines.length; i++) {
      final cur = lines[i];
      final next = lines[i + 1];
      if (cur.trim().isEmpty || _notParaStartRe.hasMatch(cur)) continue;
      if (_setextH1Re.hasMatch(next)) {
        lines[i] = '# $cur';
        lines[i + 1] = '';
        i++;
      } else if (_setextH2Re.hasMatch(next)) {
        lines[i] = '## $cur';
        lines[i + 1] = '';
        i++;
      }
    }
    return lines;
  }

  /// AST 节点 → 渲染 section；不支持的节点返回 null（调用方整块退回）
  static ReaderSection? _sectionFromNode(
    md.Node node,
    int Function(String plain, List<({int start, int end})> ranges) addProse,
  ) {
    if (node is! md.Element) return null;
    switch (node.tag) {
      case 'p':
        if (_containsTag(node, 'img')) return null;
        final (plain, ranges) = _plainFromInline(node.children);
        if (!_hasLetter(plain)) return null; // 纯标点/图片行退回 MarkdownBody
        return ReaderProse(addProse(plain, ranges));
      case 'blockquote':
        final kids = _sectionsFromNodes(node.children, addProse);
        if (kids == null || kids.isEmpty) return null;
        return ReaderQuote(kids);
      case 'ul':
      case 'ol':
        return _listFromElement(node, addProse);
      case 'hr':
        return const ReaderHr();
      default:
        final m = RegExp(r'^h([1-6])$').firstMatch(node.tag);
        if (m != null) {
          return ReaderHeading(int.parse(m.group(1)!), node.textContent.trim());
        }
        return null; // pre / table / html 等整块退回
    }
  }

  static List<ReaderSection>? _sectionsFromNodes(
    List<md.Node>? nodes,
    int Function(String, List<({int start, int end})>) addProse,
  ) {
    final out = <ReaderSection>[];
    for (final n in nodes ?? const <md.Node>[]) {
      final s = _sectionFromNode(n, addProse);
      if (s == null) return null;
      out.add(s);
    }
    return out;
  }

  /// 列表 AST → ReaderList。紧凑列表项的行内内容直接挂在 li 下；
  /// 宽松列表项的文本包在 `<p>` 里；嵌套列表递归。li 含 pre/table 等
  /// 不支持节点时返回 null，整块退回 MarkdownBody。
  static ReaderList? _listFromElement(
    md.Element list,
    int Function(String, List<({int start, int end})>) addProse,
  ) {
    final items = <ReaderListItem>[];
    for (final liNode in list.children ?? const <md.Node>[]) {
      if (liNode is! md.Element || liNode.tag != 'li') return null;
      if (_containsTag(liNode, 'img')) return null;
      final blocks = <ReaderSection>[];
      final inlineBuf = <md.Node>[];

      void flushInline() {
        if (inlineBuf.isEmpty) return;
        final (plain, ranges) = _plainFromInline(inlineBuf);
        inlineBuf.clear();
        if (!_hasLetter(plain)) return;
        blocks.add(ReaderProse(addProse(plain, ranges)));
      }

      for (final c in liNode.children ?? const <md.Node>[]) {
        if (c is md.Element && _blockTags.contains(c.tag)) {
          flushInline();
          final s = _sectionFromNode(c, addProse);
          if (s == null) return null;
          blocks.add(s);
        } else {
          inlineBuf.add(c); // Text / code / strong / a / input 等行内节点
        }
      }
      flushInline();
      if (blocks.isEmpty) return null;
      items.add(ReaderListItem(blocks));
    }
    return ReaderList(ordered: list.tag == 'ol', items: items);
  }
}
