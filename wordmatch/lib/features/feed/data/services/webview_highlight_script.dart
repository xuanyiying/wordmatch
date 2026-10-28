// WebView（应用内浏览器页）划词标注注入脚本。
//
// 标注原则：零布局影响 —— 仅给命中词加绘制层点状下划线
// （text-decoration 不参与排版），不包裹 inline-block、不插入
// 释义行，原文的换行、行高、段距、字体与配色一律不动。
// 点词不渲染页内 tooltip，通过 JavaScriptChannel
// （window.baiitEvent.postMessage）上报事件，由 Flutter 打开
// 原生生词卡展示释义。脚本自清理保证可重复注入（幂等）。
// 与 glossflow 版的差异：上报通道改为 webview_flutter JavaScriptChannel；
// skip 名单放开 'github'/'markdown-body'（GitHub 仓库页 README 正文
// 就在 markdown-body 容器内，需要标注）。
import 'dart:convert';

import '../../domain/services/local_annotation_engine.dart';
import '../../domain/services/word_lemmatizer.dart';

/// WebView 标注词条目（页内仅做下划线标记；释义由原生生词卡展示）
class WebWordAnnotation {
  final String word;

  /// learning=绿色标注；new=红色标注；faded=极淡灰痕
  final String fadeLevel;

  const WebWordAnnotation({
    required this.word,
    this.fadeLevel = 'learning',
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'fadeLevel': fadeLevel,
      };
}

/// 生成注入 WebView 的标注脚本
String buildWebviewHighlightScript(List<WebWordAnnotation> words) {
  final encoded = jsonEncode(words.map((w) => w.toJson()).toList());
  return _kScriptTemplate.replaceFirst('WORDS_PLACEHOLDER', encoded);
}

final RegExp _webWordRe =
    RegExp(r"[A-Za-z][A-Za-z'-]*[A-Za-z]|[A-Za-z]{2,}");

typedef _WebCandidate = ({String word, int rarity, int length, int order});

/// 原文页标注选词（WebView 离线判定，零 AI 成本）。
///
/// 口径与 [LocalAnnotationEngine] 对齐（词形还原命中、频序生僻度、
/// 每块密度上限），词表构成：
/// - 强制词：学习中 / 已收藏 → learning（绿色），不参与预算竞争；
/// - 预算词：词书未学词 + 频序表外的生僻词 → new（红色），每块按
///   「不在频序表 = 最生僻 > 排名越大越生僻 > 词越长」择优，
///   上限 = [maxPerBlock] 减去块内强制词数；
/// - 永不标注：停用词、已掌握、常用词（频序 ≤ 阈值）、句中大写专名。
List<WebWordAnnotation> selectWebviewAnnotations({
  required List<String> blockTexts,
  required Set<String> masteredWords,
  required Set<String> learningWords,
  required Set<String> savedWords,
  required Set<String> bookWords,
  Set<String>? stopwords,
  Set<String>? commonWords,
  Map<String, int>? frequencyRanks,
  int maxPerBlock = 8,
}) {
  final stop = stopwords ?? LocalAnnotationEngine.defaultStopwords;
  final common = commonWords ?? const <String>{};
  final ranks = frequencyRanks ?? const <String, int>{};

  bool hit(Set<String> set, String w) {
    if (set.contains(w)) return true;
    for (final c in WordLemmatizer.candidates(w)) {
      if (set.contains(c)) return true;
    }
    return false;
  }

  // 生僻度：不在频序表 = 最生僻（对齐引擎的 1<<30 约定）
  int rarity(String w) {
    var r = ranks[w];
    if (r == null) {
      for (final c in WordLemmatizer.candidates(w)) {
        final h = ranks[c];
        if (h != null) {
          r = h;
          break;
        }
      }
    }
    return r == null || r == 0 ? 1 << 30 : r;
  }

  final result = <WebWordAnnotation>[];
  final selected = <String>{};
  for (final block in blockTexts) {
    if (block.trim().isEmpty) continue;
    var forced = 0;
    final candidates = <_WebCandidate>[];
    for (final m in _webWordRe.allMatches(block)) {
      final raw = m.group(0)!;
      final w = raw.toLowerCase();
      if (stop.contains(w) || selected.contains(w)) continue;
      // 判定顺序对齐 judge()：saved > mastered > learning > common
      if (hit(savedWords, w) || hit(learningWords, w)) {
        selected.add(w);
        forced++;
        result.add(WebWordAnnotation(word: w, fadeLevel: 'learning'));
        continue;
      }
      if (hit(masteredWords, w) || hit(common, w)) continue;
      if (_isProperNoun(block, m.start, raw)) continue;
      candidates.add(
          (word: w, rarity: rarity(w), length: raw.length, order: candidates.length));
    }
    final quota = (maxPerBlock - forced).clamp(0, maxPerBlock);
    candidates.sort((a, b) {
      if (a.rarity != b.rarity) return b.rarity - a.rarity;
      if (a.length != b.length) return b.length - a.length;
      return a.order - b.order;
    });
    for (final c in candidates.take(quota)) {
      selected.add(c.word);
      result.add(WebWordAnnotation(word: c.word, fadeLevel: 'new'));
    }
  }
  return result;
}

/// 句中首字母大写或词内出现大写（GitHub/iPhone 类）视为专有名词，
/// 不按生僻词标注；块首/句首大写仍作普通词候选。
bool _isProperNoun(String text, int index, String raw) {
  if (raw == raw.toLowerCase()) return false;
  if (raw[0] == raw[0].toLowerCase() && raw != raw.toLowerCase()) return true;
  var i = index - 1;
  while (i >= 0 && (text[i] == ' ' || text[i] == '\t')) {
    i--;
  }
  if (i < 0) return false; // 块首
  final prev = text[i];
  return prev != '.' && prev != '!' && prev != '?'; // 句中 → 专名
}

const String _kScriptTemplate = r'''
(function() {
    var words = WORDS_PLACEHOLDER;

    function postEvent(payload) {
        try {
            window.baiitEvent.postMessage(JSON.stringify(payload));
        } catch (e) {
            console.log('[baiit] postEvent error: ' + e);
        }
    }

    // 仅绘制层样式：text-decoration 系列不参与布局计算，
    // 不会改变原文任何元素的排版；不新增 block/inline-block 结构。
    var CSS_STYLES = `
.baiit-word {
    cursor: pointer;
    text-decoration: underline;
    text-decoration-style: dotted;
    text-decoration-color: rgba(13, 148, 136, 0.65);
    text-decoration-thickness: 2px;
    text-underline-offset: 3px;
}
.baiit-word:hover {
    text-decoration-color: rgba(13, 148, 136, 0.95);
}
.baiit-word-new {
    text-decoration-color: rgba(239, 68, 68, 0.6);
}
.baiit-word-new:hover {
    text-decoration-color: rgba(239, 68, 68, 0.9);
}
.baiit-word-faded {
    text-decoration-color: rgba(148, 163, 184, 0.35);
    text-decoration-thickness: 1px;
}
.baiit-word-faded:hover {
    text-decoration-color: rgba(148, 163, 184, 0.6);
}
`;

    var style = document.createElement('style');
    style.id = 'baiit-annotation-styles';
    style.textContent = CSS_STYLES;

    if (!document.getElementById('baiit-annotation-styles')) {
        document.head.appendChild(style);
    }

    // 幂等清理：把上一轮注入的标注 span 还原为纯文本节点
    function removeExistingMarks() {
        var existingMarks = document.querySelectorAll('.baiit-word');
        for (var i = 0; i < existingMarks.length; i++) {
            var mark = existingMarks[i];
            var textNode = document.createTextNode(mark.textContent);
            mark.parentNode.replaceChild(textNode, mark);
        }
    }

    function escapeRegExp(str) {
        var special = '.*+?^-$' + '{}()|[]\\';
        var result = '';
        for (var i = 0; i < str.length; i++) {
            var c = str[i];
            if (special.indexOf(c) !== -1) {
                result += '\\' + c;
            } else {
                result += c;
            }
        }
        return result;
    }

    function shouldSkipElement(element) {
        if (!element || !element.tagName) return false;

        var tag = element.tagName.toLowerCase();

        var skipTags = [
            'script', 'style', 'noscript',
            'button', 'input', 'textarea', 'select', 'option',
            'a', 'code', 'pre', 'kbd', 'samp', 'var', 'tt'
        ];
        if (skipTags.indexOf(tag) !== -1) return true;

        var skipClasses = [
            'baiit-word', 'baiit-tooltip',
            'btn', 'button', 'btn-', 'button-',
            'code', 'codeblock', 'code-block', 'code_block',
            'highlight', 'hljs', 'prism', 'prettyprint',
            'language-', 'lang-', 'brush:'
        ];
        var className = element.className;
        var classList = element.classList;
        if (typeof className === 'string') {
            for (var i = 0; i < skipClasses.length; i++) {
                if (className.indexOf(skipClasses[i]) !== -1) return true;
            }
        }
        if (classList && classList.length > 0) {
            for (var i = 0; i < skipClasses.length; i++) {
                if (classList.contains(skipClasses[i])) return true;
            }
        }

        var role = element.getAttribute('role');
        if (role === 'button' || role === 'link' || role === 'navigation' || role === 'code') return true;

        var dataLang = element.getAttribute('data-lang') || element.getAttribute('data-language');
        if (dataLang) return true;

        var parent = element.parentElement;
        var maxDepth = 10;
        var depth = 0;
        while (parent && depth < maxDepth) {
            var parentTag = parent.tagName.toLowerCase();
            if (parentTag === 'code' || parentTag === 'pre' || parentTag === 'kbd' || parentTag === 'samp' || parentTag === 'var' || parentTag === 'tt') {
                return true;
            }

            if (parentTag === 'button' || parentTag === 'a') {
                return true;
            }

            var parentClass = parent.className;
            if (typeof parentClass === 'string') {
                var codeBlockPatterns = [
                    'highlight', 'hljs', 'prism', 'prettyprint',
                    'code', 'codeblock', 'code-block', 'code_block',
                    'language-', 'lang-',
                    'syntax', 'source-code'
                ];
                for (var j = 0; j < codeBlockPatterns.length; j++) {
                    if (parentClass.indexOf(codeBlockPatterns[j]) !== -1) return true;
                }

                var buttonPatterns = ['btn', 'button', 'btn-', 'button-'];
                for (var k = 0; k < buttonPatterns.length; k++) {
                    if (parentClass.indexOf(buttonPatterns[k]) !== -1) return true;
                }
            }

            var parentRole = parent.getAttribute('role');
            if (parentRole === 'button') return true;

            if (parent.getAttribute('data-lang') || parent.getAttribute('data-language')) {
                return true;
            }

            parent = parent.parentElement;
            depth++;
        }

        return false;
    }

    function highlightWords() {
        var startTime = Date.now();

        removeExistingMarks();

        var wordMap = {};
        var wordSet = new Set();
        var wordList = [];
        for (var i = 0; i < words.length; i++) {
            var w = words[i].word.toLowerCase();
            wordMap[w] = words[i];
            wordSet.add(w);
            wordList.push(w);
        }

        if (wordList.length === 0) {
            postEvent({ type: 'highlight_complete', count: 0 });
            return;
        }

        var patternStr = '\\b(' + wordList.map(function(w) { return escapeRegExp(w); }).join('|') + ')\\b';
        var combinedRegex = new RegExp(patternStr, 'gi');

        var skipCache = new WeakMap();

        function cachedShouldSkip(element) {
            if (!element) return false;
            if (skipCache.has(element)) return skipCache.get(element);
            var result = shouldSkipElement(element);
            skipCache.set(element, result);
            return result;
        }

        var walker = document.createTreeWalker(
            document.body,
            NodeFilter.SHOW_TEXT,
            {
                acceptNode: function(node) {
                    if (cachedShouldSkip(node.parentElement)) {
                        return NodeFilter.FILTER_REJECT;
                    }
                    var text = node.textContent;
                    if (!text || text.trim().length < 3) {
                        return NodeFilter.FILTER_REJECT;
                    }
                    return NodeFilter.FILTER_ACCEPT;
                }
            }
        );

        var textNodes = [];
        var nodeCount = 0;
        var maxNodes = 2000;
        while (walker.nextNode() && nodeCount < maxNodes) {
            textNodes.push(walker.currentNode);
            nodeCount++;
        }

        var highlightedCount = 0;
        var processedNodes = 0;
        var maxProcessedNodes = 600;

        function processBatch(startIndex) {
            var endIndex = Math.min(startIndex + 50, textNodes.length);

            for (var n = startIndex; n < endIndex; n++) {
                var node = textNodes[n];
                var text = node.textContent;
                var wordsToHighlight = [];

                var match;
                combinedRegex.lastIndex = 0;
                while ((match = combinedRegex.exec(text)) !== null) {
                    var matchedWord = match[1].toLowerCase();
                    if (wordSet.has(matchedWord) && wordMap[matchedWord]) {
                        wordsToHighlight.push({
                            word: wordMap[matchedWord],
                            index: match.index,
                            length: match[0].length
                        });
                    }
                }

                if (wordsToHighlight.length === 0) continue;

                wordsToHighlight.sort(function(a, b) { return b.index - a.index; });

                var deduped = [];
                var seen = new Set();
                for (var h = 0; h < wordsToHighlight.length; h++) {
                    var item = wordsToHighlight[h];
                    var key = item.index + '-' + item.length;
                    if (!seen.has(key)) {
                        seen.add(key);
                        deduped.push(item);
                    }
                }
                wordsToHighlight = deduped;

                var parent = node.parentNode;
                if (!parent) continue;

                var fragment = document.createDocumentFragment();
                var lastIndex = text.length;

                for (var h = 0; h < wordsToHighlight.length; h++) {
                    var item = wordsToHighlight[h];

                    if (lastIndex > item.index + item.length) {
                        fragment.insertBefore(document.createTextNode(text.slice(item.index + item.length, lastIndex)), fragment.firstChild);
                    }

                    // 纯内联 span（默认 display:inline），文本与原文字符
                    // 完全一致，不产生额外盒子、不插入释义行，排版零影响；
                    // 释义由点词上报后的原生生词卡展示。
                    var fadeLevel = item.word.fadeLevel || 'learning';
                    var fadeClass = fadeLevel === 'new' ? ' baiit-word-new'
                        : fadeLevel === 'faded' ? ' baiit-word-faded' : '';

                    var span = document.createElement('span');
                    span.className = 'baiit-word' + fadeClass;
                    span.textContent = text.slice(item.index, item.index + item.length);
                    span.setAttribute('data-word', item.word.word);

                    (function(wordInfo, spanEl) {
                        var isLongPress = false;
                        var pressTimer = null;

                        function contextSentence() {
                            var el = spanEl;
                            for (var up = 0; up < 6 && el.parentElement; up++) {
                                el = el.parentElement;
                                var tag = el.tagName ? el.tagName.toLowerCase() : '';
                                if (tag === 'p' || tag === 'li' || tag === 'blockquote' || tag === 'h1' || tag === 'h2' || tag === 'h3') break;
                            }
                            var sentence = (el.textContent || '').replace(/\s+/g, ' ').trim();
                            return sentence.length > 200 ? sentence.slice(0, 200) : sentence;
                        }

                        function buildPayload(extraType) {
                            return {
                                type: extraType,
                                word: wordInfo.word,
                                sentence: contextSentence()
                            };
                        }

                        spanEl.addEventListener('touchstart', function(e) {
                            isLongPress = false;
                            pressTimer = setTimeout(function() {
                                isLongPress = true;
                                e.preventDefault();
                                e.stopPropagation();
                                postEvent(buildPayload('word_long_press'));
                            }, 500);
                        }, { passive: false });

                        spanEl.addEventListener('touchend', function(e) {
                            if (pressTimer) {
                                clearTimeout(pressTimer);
                                pressTimer = null;
                            }
                            if (!isLongPress) {
                                e.preventDefault();
                                e.stopPropagation();
                                postEvent(buildPayload('word_click'));
                            }
                        }, { passive: false });

                        spanEl.addEventListener('click', function(e) {
                            e.preventDefault();
                            e.stopPropagation();
                        });
                    })(item.word, span);

                    fragment.insertBefore(span, fragment.firstChild);
                    lastIndex = item.index;
                    highlightedCount++;
                }

                if (lastIndex > 0) {
                    fragment.insertBefore(document.createTextNode(text.slice(0, lastIndex)), fragment.firstChild);
                }

                parent.replaceChild(fragment, node);
                processedNodes++;
            }

            if (endIndex < textNodes.length && processedNodes < maxProcessedNodes) {
                requestAnimationFrame(function() {
                    processBatch(endIndex);
                });
            } else {
                var elapsed = Date.now() - startTime;
                console.log('[baiit] 标注完成: ' + highlightedCount + ' 词, 耗时 ' + elapsed + 'ms');
                postEvent({ type: 'highlight_complete', count: highlightedCount });
            }
        }

        processBatch(0);
    }

    highlightWords();
})();
''';
