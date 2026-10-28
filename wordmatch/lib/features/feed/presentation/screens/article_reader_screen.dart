import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/feed/data/repositories/feed_repository.dart';
import 'package:wordmatch/features/feed/data/services/dictionary_service.dart';
import 'package:wordmatch/features/feed/data/services/semantic_annotator_service.dart';
import 'package:wordmatch/features/feed/data/services/word_frequency_service.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';
import 'package:wordmatch/features/feed/domain/services/annotation_models.dart';
import 'package:wordmatch/features/feed/domain/services/article_markdown_parser.dart';
import 'package:wordmatch/features/feed/domain/services/local_annotation_engine.dart';
import 'package:wordmatch/features/feed/presentation/widgets/annotated_paragraph.dart';
import 'package:wordmatch/features/feed/presentation/widgets/word_lookup_sheet.dart';
import 'package:wordmatch/features/game/data/repositories/game_provider.dart';
import 'package:wordmatch/features/wordbook/data/repositories/custom_wordbook_repository.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';
import 'package:wordmatch/features/wordbook/data/repositories/wordbook_repository.dart';
import 'package:wordmatch/shared/utils/external_link.dart';

/// 阅读页路由参数
class ArticleReaderArgs {
  final FeedSource source;
  final String id;

  const ArticleReaderArgs({required this.source, required this.id});
}

/// 文章阅读页（掰it 式划词标注）：
/// 1. 本地引擎基于学习状态立即生成粗标注（离线可用）
/// 2. AI 语境语义分析在后台执行，返回后覆盖合并（语境义项/短语/排除术语）
/// 3. 点词弹卡查词（音标+语境义+释义+发音），可一键收藏进「阅读生词本」
class ArticleReaderScreen extends ConsumerStatefulWidget {
  final ArticleReaderArgs args;

  const ArticleReaderScreen({super.key, required this.args});

  @override
  ConsumerState<ArticleReaderScreen> createState() =>
      _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends ConsumerState<ArticleReaderScreen> {
  ArticleContent? _article;
  String? _error;
  bool _loadingArticle = true;

  /// 渲染块（markdown 解析得到；ReaderBlock.sections 非空即走划词标注渲染）
  List<ReaderBlock> _blocks = const [];

  /// prose 段落纯文本（序号与 blocks 中的 proseIndex 对齐，供 AI 分析）
  List<String> _proseBlocks = const [];

  /// 各 prose 段落的行内代码区间（序号与 [_proseBlocks] 对齐）
  List<List<({int start, int end})>> _proseCodeRanges = const [];

  LocalAnnotationEngine? _engine;

  /// 本次阅读中已收藏词（lowercase → learning）
  Map<String, WordStatus> _savedWords = {};

  /// AI 语义分析结果（按段落）
  SemanticResult? _semantic;

  /// AI 分析/语境释义进行中（顶栏进度条）
  bool _analyzing = false;

  /// 批量语境释义（word 小写 → AI 语境义），覆盖词典首义兜底
  Map<String, String> _contextGlosses = const {};

  /// 段落渲染缓存：proseIndex → 富文本+取词映射；收藏/语义结果更新时定向失效
  final Map<int, AnnotatedParagraph> _paraCache = {};

  /// 各 prose 段落的 key（长按时借 RenderParagraph 把坐标换成字符偏移）
  final Map<int, GlobalKey> _paraKeys = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 常用词表须先就绪，_loadEngine 构造引擎时就要注入（避免竞态取到空表）
    await WordFrequencyService.ensureLoaded();
    // 并行：本地引擎数据 + 已收藏词 + 文章正文
    // 词典预加载：本地标注词的行内首义括注依赖同步查询
    await Future.wait([
      _loadEngine(),
      _loadSavedWords(),
      DictionaryService.ensureLoaded(),
    ]);
    await _openArticle();
  }

  /// 判定数据源：当前词书词表 + 学习进度
  Future<void> _loadEngine() async {
    try {
      final bookId = ref.read(currentBookIdProvider);
      final repo = WordbookRepository();
      final words = await repo.loadBook(bookId);

      final storage = ref.read(progressStorageProvider);
      final mastered = <String>{};
      final learning = <String>{};
      final bookWords = <String>{};
      for (final w in words) {
        bookWords.add(w.word.toLowerCase());
        final p = storage.getProgress(w.id);
        if (p == null) continue;
        if (p.isMastered) {
          mastered.add(w.word.toLowerCase());
        } else {
          learning.add(w.word.toLowerCase());
        }
      }
      if (!mounted) return;
      setState(() {
        _engine = LocalAnnotationEngine(
          masteredWords: mastered,
          learningWords: learning,
          bookWords: bookWords,
          commonWords: WordFrequencyService.commonWords(),
          frequencyRanks: WordFrequencyService.ranks(),
        );
      });
    } catch (_) {
      // 引擎数据加载失败：不标注（AI 语义分析仍可用）
    }
  }

  /// 「阅读生词本」已有词
  Future<void> _loadSavedWords() async {
    try {
      final repo = CustomWordbookRepository();
      await repo.getOrCreateReadingBook();
      final words = await repo.loadWords(CustomWordbookRepository.readingBookId);
      if (!mounted) return;
      setState(() {
        _savedWords = {
          for (final w in words ?? const <Word>[])
            w.word.toLowerCase(): WordStatus.learning,
        };
      });
    } catch (_) {
      // 生词本不可用不影响阅读
    }
  }

  Future<void> _openArticle() async {
    setState(() {
      _loadingArticle = true;
      _error = null;
    });
    try {
      final article = await FeedRepository.instance
          .getArticle(widget.args.source, widget.args.id);
      if (!mounted) return;
      setState(() {
        _article = article;
        _loadingArticle = false;
        _rebuildBlocks(article.markdown);
      });
      _runSemanticAnalysis();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingArticle = false;
        _error = '文章加载失败：$e';
      });
    }
  }

  Future<void> _runSemanticAnalysis() async {
    if (_proseBlocks.isEmpty) return;
    setState(() => _analyzing = true);
    // 本地预筛：零候选段落不发 AI 请求（本地也不会标注，零损失），
    // 非空候选注入提示词供 AI 逐词判断
    final engine = _engine;
    final savedKeys = _savedWords.keys.toSet();
    final result = await SemanticAnnotatorService.analyzeArticle(
      sourceId: widget.args.source.name,
      articleId: widget.args.id,
      paragraphs: _proseBlocks,
      candidates: engine == null
          ? null
          : [
              for (var i = 0; i < _proseBlocks.length; i++)
                engine.aiCandidates(_proseBlocks[i], savedWords: savedKeys),
            ],
    );
    if (!mounted) return;
    setState(() {
      if (result != null) {
        _semantic = result;
        _paraCache.clear(); // 语义结果覆盖重渲染
      }
    });

    // 段落语义每段最多 8 词且有正文长度上限，覆盖不到的本地标注词若回退
    // 词典首义会脱离语境；这里把全部待释义词连同所在句批量送 AI 补齐
    final covered = {
      for (final p in _semantic?.paragraphs ?? const <ParagraphAnnotation>[])
        for (final t in p.tokens) t.surface.toLowerCase(),
    };
    final items = <({String word, String sentence})>[];
    if (engine != null) {
      final seen = <String>{};
      for (var i = 0; i < _proseBlocks.length; i++) {
        final spans = engine.processParagraph(
          _proseBlocks[i],
          savedWords: savedKeys,
          skipRanges: _proseCodeRanges[i],
        );
        for (final s in spans) {
          if (!s.isAnnotated) continue;
          final w = s.rawWord.toLowerCase();
          if (covered.contains(w) || !seen.add(w)) continue;
          items.add((
            word: w,
            sentence: _sentenceFor(_proseBlocks[i], s.rawWord),
          ));
        }
      }
    }
    final glosses = await SemanticAnnotatorService.glossWords(
      sourceId: widget.args.source.name,
      articleId: widget.args.id,
      items: items,
    );
    if (!mounted) return;
    setState(() {
      _analyzing = false;
      if (glosses.isNotEmpty) {
        _contextGlosses = {..._contextGlosses, ...glosses};
        _paraCache.clear(); // 语境释义到位，重渲染
      }
    });
  }

  // ============ markdown 块切分与标注范围 ============
  //
  // 解析逻辑见 ArticleMarkdownParser：<p>、<blockquote> 内段落、
  // <ul>/<ol> 列表项文本都产出 prose；代码块/表格/HTML 整块退回
  // MarkdownBody；标题紧邻段落等多节点块逐个转换。

  void _rebuildBlocks(String markdown) {
    final parsed = ArticleMarkdownParser.parse(markdown);
    setState(() {
      _blocks = parsed.blocks;
      _proseBlocks = parsed.prose;
      _proseCodeRanges = parsed.codeRanges;
      _paraCache.clear();
      _paraKeys.clear();
      _semantic = null;
    });
  }

  // ============ 标注渲染 ============

  AnnotatedParagraph _buildParagraph(int proseIndex, TextStyle base) {
    return _paraCache.putIfAbsent(proseIndex, () {
      final engine = _engine;
      final plain = _proseBlocks[proseIndex];
      final spans = engine == null
          ? [WordSpan(plain, WordStatus.graduated)]
          : _annotatePlain(engine, proseIndex, plain);
      return buildAnnotatedParagraph(
        spans,
        base: base,
        onTap: (w) => _onWordTap(w, proseIndex),
      );
    });
  }

  List<WordSpan> _annotatePlain(
      LocalAnnotationEngine engine, int proseIndex, String plain) {
    final tokens = _semantic?.byParagraph[proseIndex];
    final glosses = tokens == null
        ? const <String, String>{}
        : {for (final t in tokens) t.surface.toLowerCase(): t.gloss};
    // 行内代码区间由 markdown AST 记录，标注引擎跳过。
    // AI 词与本地词书词合并：词书未学词始终保留（学习目标），
    // 密度总预算优先让给带语境义的 AI 词
    final spans = engine.processParagraph(
      plain,
      forcedGlosses: glosses,
      savedWords: _savedWords.keys.toSet(),
      skipRanges: _proseCodeRanges[proseIndex],
    );
    // 括注语境义优先级：批量语境释义 > AI 段落语义（同词多次出现时仅
    // 首处走强制区间携带 gloss，其余回落至此）> 词典常用义兜底
    return [
      for (final s in spans)
        if (!s.isAnnotated ||
            (s.contextGloss != null && s.contextGloss!.isNotEmpty))
          s
        else
          WordSpan(
            s.text,
            s.status,
            rawWord: s.rawWord,
            contextGloss: _fallbackGloss(s.rawWord, glosses),
          ),
    ];
  }

  /// 行内括注的逐级兜底：批量语境释义（本词原形）→ AI 段落语义（同词
  /// surface）→ 词典最常用义（含词形还原）。
  String? _fallbackGloss(String rawWord, Map<String, String> semanticGlosses) {
    final w = rawWord.toLowerCase();
    final batch = _contextGlosses[w];
    if (batch != null && batch.isNotEmpty) return batch;
    final semantic = semanticGlosses[w];
    if (semantic != null && semantic.isNotEmpty) return semantic;
    return DictionaryService.briefDefinition(rawWord);
  }

  void _onWordTap(String word, int proseIndex) {
    final lower = word.toLowerCase();
    final tokens = _semantic?.byParagraph[proseIndex];
    // 弹卡语境义与括注同优先级：AI 段落语义 > 批量语境释义
    String? gloss = _contextGlosses[lower];
    if (tokens != null) {
      for (final t in tokens) {
        if (t.surface.toLowerCase() == lower) {
          gloss = t.gloss;
          break;
        }
      }
    }
    showWordLookupSheet(
      context,
      word: word,
      contextGloss: gloss,
      sentence: _sentenceFor(_proseBlocks[proseIndex], word),
      alreadySaved: _savedWords.containsKey(lower),
      sourceId: widget.args.source.name,
      articleId: widget.args.id,
      onSaved: () {
        setState(() {
          _savedWords[lower] = WordStatus.learning;
          // 只重建包含该词的段落，其余段落命中缓存
          _paraCache.removeWhere((_, para) => para.words.contains(lower));
        });
      },
      onGlossResolved: (resolvedWord, resolvedGloss) {
        // 弹卡按需 AI 查词的结果并入本会话括注，定向重建相关段落
        final key = resolvedWord.toLowerCase();
        setState(() {
          _contextGlosses = {..._contextGlosses, key: resolvedGloss};
          _paraCache.removeWhere((_, para) => para.words.contains(key));
        });
      },
    );
  }

  /// 长按任意单词（含未标注词）取词弹释义卡：
  /// 长按坐标 → 渲染字符偏移 → 原文偏移 → 单词
  void _onWordLongPress(LongPressStartDetails details, int proseIndex) {
    final ro = _paraKeys[proseIndex]?.currentContext?.findRenderObject();
    if (ro is! RenderParagraph) return;
    final pos =
        ro.getPositionForOffset(ro.globalToLocal(details.globalPosition));
    final para = _paraCache[proseIndex];
    if (para == null) return;
    final word = para.wordAtRenderOffset(_proseBlocks[proseIndex], pos.offset);
    if (word != null) _onWordTap(word, proseIndex);
  }

  /// 提取包含目标词的句子（供 AI 查词带上下文）
  static String _sentenceFor(String text, String word) {
    final sentences =
        text.split(RegExp(r'(?<=[.!?])\s+'));
    for (final s in sentences) {
      if (RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false)
          .hasMatch(s)) {
        return s;
      }
    }
    return text;
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _article?.title ?? '文章',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.ink),
        ),
        actions: [
          // 应用内 WebView 查看原文（GitHub 仓库页 / dev.to 文章页等）
          if ((_article?.url ?? '').isNotEmpty)
            IconButton(
              onPressed: () => openInAppBrowser(
                context,
                _article!.url,
                title: _article!.title,
              ),
              icon: const Icon(Icons.open_in_browser),
              color: colors.inkSoft,
              tooltip: '查看原文',
            ),
        ],
        bottom: _analyzing
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: colors.mintBg,
                  valueColor: AlwaysStoppedAnimation(colors.mintDeep),
                ),
              )
            : null,
      ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(AppColorScheme colors) {
    if (_loadingArticle) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 44, color: colors.inkFaint),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.inkSoft),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _openArticle,
              style: FilledButton.styleFrom(backgroundColor: colors.mintDeep),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final article = _article!;
    final baseStyle = TextStyle(
      fontSize: 16,
      height: 1.75,
      color: colors.ink,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部信息
          Text(
            article.title,
            style: TextStyle(
              fontSize: 24,
              height: 1.3,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (article.author.isNotEmpty) article.author,
              if (article.publishedAt.isNotEmpty) article.publishedAt,
            ].join(' · '),
            style: TextStyle(fontSize: 12, color: colors.inkFaint),
          ),
          const SizedBox(height: 20),

          // 正文
          for (final block in _blocks)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: block.sections.isEmpty
                  ? _fallbackMarkdown(block.raw, colors)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < block.sections.length; i++) ...[
                          _sectionWidget(
                              block.sections[i], baseStyle, colors),
                          if (i < block.sections.length - 1)
                            const SizedBox(height: 10),
                        ],
                      ],
                    ),
            ),

          const SizedBox(height: 8),
          // 署名导流
          Center(
            child: Text(
              'Content from ${article.source.label} · 仅供学习交流',
              style: TextStyle(fontSize: 11, color: colors.inkFaint),
            ),
          ),
        ],
      ),
    );
  }

  // ============ section 渲染 ============

  /// 不支持的 markdown 结构（代码块/表格/HTML 等）保留原渲染
  Widget _fallbackMarkdown(String raw, AppColorScheme colors) {
    return MarkdownBody(
      data: raw,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      // 正文内链接（README 引用仓库/文章等）点击后应用内打开
      onTapLink: (text, href, title) {
        if (href == null || href.isEmpty) return;
        openInAppBrowser(context, href, title: text);
      },
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: 15, height: 1.6, color: colors.ink),
        a: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: colors.mintDeep,
          decoration: TextDecoration.underline,
          decorationColor: colors.mintDeep,
        ),
        code: TextStyle(
            fontSize: 13, color: colors.ink, backgroundColor: colors.mintBg),
        codeblockDecoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
              left: BorderSide(color: colors.mintLight, width: 3)),
        ),
        blockquote:
            TextStyle(fontSize: 15, height: 1.6, color: colors.inkSoft),
        h1: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800, color: colors.ink),
        h2: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: colors.ink),
        h3: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: colors.ink),
      ),
    );
  }

  Widget _sectionWidget(
      ReaderSection section, TextStyle baseStyle, AppColorScheme colors) {
    if (section is ReaderProse) {
      return _proseWidget(section.proseIndex, baseStyle);
    }
    if (section is ReaderHeading) {
      const sizes = {1: 22.0, 2: 18.0, 3: 16.0, 4: 15.0, 5: 14.0, 6: 14.0};
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: Text(
          section.text,
          style: TextStyle(
            fontSize: sizes[section.level],
            height: 1.35,
            fontWeight:
                section.level <= 2 ? FontWeight.w800 : FontWeight.w700,
            color: colors.ink,
          ),
        ),
      );
    }
    if (section is ReaderHr) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Divider(height: 1, color: colors.border),
      );
    }
    if (section is ReaderQuote) {
      return Container(
        decoration: BoxDecoration(
          border:
              Border(left: BorderSide(color: colors.mintLight, width: 3)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 2, 0, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < section.children.length; i++) ...[
              _sectionWidget(section.children[i], baseStyle, colors),
              if (i < section.children.length - 1)
                const SizedBox(height: 8),
            ],
          ],
        ),
      );
    }
    if (section is ReaderList) {
      return _listWidget(section, baseStyle, colors);
    }
    return const SizedBox.shrink();
  }

  /// 可划词标注的 prose 段落（长按任意单词弹释义卡；点标注词走 span 点击）
  Widget _proseWidget(int proseIndex, TextStyle baseStyle) {
    return GestureDetector(
      onLongPressStart: (d) => _onWordLongPress(d, proseIndex),
      child: RichText(
        key: _paraKeys.putIfAbsent(proseIndex, () => GlobalKey()),
        text: _buildParagraph(proseIndex, baseStyle).root,
      ),
    );
  }

  Widget _listWidget(
      ReaderList list, TextStyle baseStyle, AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < list.items.length; i++)
          Padding(
            padding:
                EdgeInsets.only(bottom: i < list.items.length - 1 ? 6 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      list.ordered ? '${i + 1}.' : '•',
                      style: baseStyle.copyWith(color: colors.inkSoft),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final b in list.items[i].blocks)
                        _sectionWidget(b, baseStyle, colors),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
