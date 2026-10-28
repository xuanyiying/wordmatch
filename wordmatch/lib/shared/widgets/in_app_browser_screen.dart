import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/feed/data/services/dictionary_service.dart';
import 'package:wordmatch/features/feed/data/services/word_frequency_service.dart';
import 'package:wordmatch/features/feed/data/services/webview_highlight_script.dart';
import 'package:wordmatch/features/feed/presentation/widgets/word_lookup_sheet.dart';
import 'package:wordmatch/features/game/data/repositories/game_provider.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';
import 'package:wordmatch/features/wordbook/data/repositories/custom_wordbook_repository.dart';
import 'package:wordmatch/features/wordbook/data/repositories/wordbook_repository.dart';

/// 应用内浏览器页：WebView 加载外部链接（GitHub 仓库 / 资讯原文等）。
/// 页面加载完成后注入划词标注：生僻词优先（频序表 + 词书状态离线判定，
/// 零 AI 成本）+ 词书「学习中」词 + 阅读生词本词，点词弹原生查词卡
/// （查词/发音/收藏），与阅读页同一套交互。页内只加绘制层下划线，
/// 不改动原站任何样式。
class InAppBrowserScreen extends ConsumerStatefulWidget {
  final String url;

  /// AppBar 标题兜底（网页标题加载成功后优先显示网页标题）
  final String? title;

  const InAppBrowserScreen({super.key, required this.url, this.title});

  @override
  ConsumerState<InAppBrowserScreen> createState() =>
      _InAppBrowserScreenState();
}

class _InAppBrowserScreenState extends ConsumerState<InAppBrowserScreen> {
  WebViewController? _controller;
  int _progress = 0;
  String _pageTitle = '';
  bool _pageFinished = false;

  /// 标注数据就绪（异步加载完成后允许注入）
  bool _annotationsReady = false;

  /// 已掌握词（lowercase，不标注）
  Set<String> _mastered = {};

  /// 词书中学习中的词（lowercase）
  Set<String> _learningWords = {};

  /// 阅读生词本已收藏词（lowercase），收藏后重注入立即高亮
  Set<String> _savedWords = {};

  /// 当前词书全词表（lowercase），生僻词判定中的「学习目标」候选
  Set<String> _bookWords = {};

  /// 首次注入时采集的原文分块文本；收藏重注入时复用，避免二次采集
  List<String>? _pageBlocks;

  @override
  void initState() {
    super.initState();
    _initController();
    _loadAnnotations();
  }

  void _initController() {
    final uri = Uri.tryParse(widget.url.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return;
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'baiitEvent',
        onMessageReceived: (msg) => _onJsEvent(msg.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onPageFinished: (_) async {
            if (!mounted) return;
            setState(() => _pageFinished = true);
            try {
              final t = await _controller?.getTitle();
              if (mounted && t != null && t.isNotEmpty) {
                setState(() => _pageTitle = t);
              }
            } catch (_) {
              // 网页标题获取失败：回退显示传入标题/host
            }
            // GitHub 等站点正文渲染稍晚于 load 完成事件，延迟注入
            await Future.delayed(const Duration(milliseconds: 600));
            _injectAnnotations();
          },
        ),
      )
      ..loadRequest(uri);
  }

  /// 标注数据：词书词表 + 学习进度 + 阅读生词本 + 离线词典 + 频序词表
  Future<void> _loadAnnotations() async {
    try {
      await DictionaryService.ensureLoaded();
      await WordFrequencyService.ensureLoaded();
      final bookId = ref.read(currentBookIdProvider);
      final words = await WordbookRepository().loadBook(bookId);
      final storage = ref.read(progressStorageProvider);
      final mastered = <String>{};
      final learning = <String>{};
      final book = <String>{};
      for (final w in words) {
        final lower = w.word.toLowerCase();
        book.add(lower);
        final p = storage.getProgress(w.id);
        if (p == null) continue;
        (p.isMastered ? mastered : learning).add(lower);
      }
      final saved = await _loadSavedWords();
      if (!mounted) return;
      setState(() {
        _mastered = mastered;
        _learningWords = learning;
        _savedWords = saved;
        _bookWords = book;
        _annotationsReady = true;
      });
      // 页面先于数据就绪时补偿注入
      if (_pageFinished) _injectAnnotations();
    } catch (_) {
      // 标注数据加载失败：页面正常打开，仅无标注
    }
  }

  Future<Set<String>> _loadSavedWords() async {
    try {
      final repo = CustomWordbookRepository();
      await repo.getOrCreateReadingBook();
      final words =
          await repo.loadWords(CustomWordbookRepository.readingBookId);
      return {for (final w in words ?? const <Word>[]) w.word.toLowerCase()};
    } catch (_) {
      return {};
    }
  }

  /// 组装注入词表：生僻词优先（Dart 侧离线判定，零 AI 成本）
  ///
  /// 有原文分块时走 [selectWebviewAnnotations]：学习中/已收藏强制标注，
  /// 词书未学词 + 频序表外生僻词每块择优；块采集失败时退回
  /// 「学习中 + 已收藏」全量词表（老行为兜底）。
  List<WebWordAnnotation> _wordsForScript(List<String>? blocks) {
    if (blocks == null) {
      final fallback = <WebWordAnnotation>[];
      final seen = <String>{};
      void add(String raw) {
        final w = raw.toLowerCase().trim();
        if (w.isEmpty || _mastered.contains(w) || !seen.add(w)) return;
        fallback.add(WebWordAnnotation(word: w));
      }

      _learningWords.forEach(add);
      _savedWords.forEach(add);
      return fallback;
    }
    return selectWebviewAnnotations(
      blockTexts: blocks,
      masteredWords: _mastered,
      learningWords: _learningWords,
      savedWords: _savedWords,
      bookWords: _bookWords,
      commonWords: WordFrequencyService.commonWords(),
      frequencyRanks: WordFrequencyService.ranks(),
    );
  }

  /// 注入标注脚本（两阶段：采集原文分块 → Dart 选词 → 注入；
  /// 脚本自清理，可重复注入）
  Future<void> _injectAnnotations() async {
    final c = _controller;
    if (c == null || !_annotationsReady) return;
    try {
      _pageBlocks ??= await _collectPageBlocks(c);
      await c.runJavaScript(
          buildWebviewHighlightScript(_wordsForScript(_pageBlocks)));
    } catch (_) {
      // 注入失败（页面跳转中等）：忽略
    }
  }

  /// 采集原文分块文本（p/li/引用/标题等块级容器的纯文本），
  /// 供 Dart 侧做生僻词判定；失败返回 null（退回全量词表兜底）
  Future<List<String>?> _collectPageBlocks(WebViewController c) async {
    try {
      final raw = await c.runJavaScriptReturningResult(_kCollectBlocksJs);
      var s = raw is String ? raw : raw.toString();
      // Android evaluateJavascript 对字符串结果做 JSON 编码（带引号），需还原
      if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
        try {
          s = jsonDecode(s) as String;
        } catch (_) {
          // 非 JSON 编码字符串：按原文处理
        }
      }
      return (jsonDecode(s) as List).cast<String>();
    } catch (_) {
      return null;
    }
  }

  /// JS 上报的点词事件 → 原生查词卡
  void _onJsEvent(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final word = (data['word'] ?? '').toString().trim();
      if (word.isEmpty || !mounted) return;
      final sentence = (data['sentence'] ?? '').toString();
      final lower = word.toLowerCase();
      showWordLookupSheet(
        context,
        word: word,
        contextGloss: DictionaryService.briefDefinition(word),
        sentence: sentence.isEmpty ? null : sentence,
        alreadySaved: _savedWords.contains(lower),
        onSaved: () {
          if (!mounted) return;
          setState(() => _savedWords.add(lower));
          _injectAnnotations();
        },
      );
    } catch (_) {
      // 非 JSON 消息：忽略
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final host = Uri.tryParse(widget.url)?.host ?? '';
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _pageTitle.isNotEmpty ? _pageTitle : (widget.title ?? host),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.ink,
          ),
        ),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 2,
                  backgroundColor: colors.mintBg,
                  valueColor: AlwaysStoppedAnimation(colors.mintDeep),
                ),
              )
            : null,
      ),
      body: _controller == null
          ? Center(
              child: Text('链接无效', style: TextStyle(color: colors.inkSoft)),
            )
          : WebViewWidget(controller: _controller!),
    );
  }
}

/// 原文分块采集脚本：按块级容器（p/li/引用/标题/表格单元格等）收集
/// 可见正文文本，跳过链接/代码/按钮等交互与代码区域（与标注脚本同一
/// 口径），返回 JSON 字符串数组供 Dart 侧做生僻词判定。
/// 只读操作，不改动页面任何内容与样式。
const String _kCollectBlocksJs = r'''
(function() {
    try {
        var skipTags = { SCRIPT:1, STYLE:1, NOSCRIPT:1, BUTTON:1, INPUT:1,
            TEXTAREA:1, SELECT:1, OPTION:1, A:1, CODE:1, PRE:1, KBD:1,
            SAMP:1, VAR:1, TT:1 };
        function shouldSkip(el) {
            var depth = 0;
            while (el && depth < 10) {
                if (skipTags[el.tagName]) return true;
                var cls = typeof el.className === 'string' ? el.className : '';
                if (cls.indexOf('baiit-word') !== -1) return true;
                if (/code|hljs|highlight|prism|language-|btn-|button-/i.test(cls)) return true;
                var role = el.getAttribute && el.getAttribute('role');
                if (role === 'button' || role === 'link') return true;
                el = el.parentElement;
                depth++;
            }
            return false;
        }
        var blockRe = /^(P|LI|BLOCKQUOTE|H1|H2|H3|H4|TD|TH|DD|DT)$/;
        var buckets = new Map();
        var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
            acceptNode: function(n) {
                var t = n.textContent;
                if (!t || t.trim().length < 2) return NodeFilter.FILTER_REJECT;
                if (shouldSkip(n.parentElement)) return NodeFilter.FILTER_REJECT;
                return NodeFilter.FILTER_ACCEPT;
            }
        });
        var count = 0;
        while (walker.nextNode() && count < 6000) {
            var node = walker.currentNode;
            var el = node.parentElement, block = null, depth = 0;
            while (el && depth < 12) {
                if (blockRe.test(el.tagName)) { block = el; break; }
                el = el.parentElement;
                depth++;
            }
            var key = block || node.parentElement;
            if (!key) continue;
            var arr = buckets.get(key);
            if (!arr) { arr = []; buckets.set(key, arr); }
            arr.push(node.textContent);
            count++;
        }
        var out = [];
        buckets.forEach(function(parts) { out.push(parts.join(' ')); });
        return JSON.stringify(out);
    } catch (err) {
        return '[]';
    }
})();
''';
