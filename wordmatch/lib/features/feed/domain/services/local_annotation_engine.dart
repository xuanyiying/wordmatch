import 'annotation_models.dart';
import 'word_lemmatizer.dart';

/// 本地标注引擎（降级/初稿用）
///
/// 基于学习状态做秒级粗标注：已掌握不标、学习中的浅色高亮、
/// 当前词书内未学习的生词虚线标注。AI 语境语义分析结果作为
/// 强制标注区间与语境义来源与之合并——词书内未学词是学习目标，
/// 即使 AI 未选中也保留本地标注；密度预算优先让给带语境义的 AI 词。
class LocalAnnotationEngine {
  /// 已掌握词表（lowercase）
  final Set<String> masteredWords;

  /// 学习中词表（lowercase，有进度未掌握）
  final Set<String> learningWords;

  /// 当前所选词书词表（lowercase；未学习时作为 unfamiliar 候选）
  final Set<String> bookWords;

  /// 停用词表（lowercase，永不标注）
  final Set<String> stopwords;

  /// 常用词表（lowercase，词频排名 ≤ 阈值）：在词书内但未学习也不自动标注。
  /// 学习中/已收藏的词不受此限制。
  final Set<String> commonWords;

  /// 词 → 词频排名（1 起，越小越常见；缺表/不在表内为 0=生僻），
  /// 密度超限择优时按「越生僻越优先」排序。
  final Map<String, int> frequencyRanks;

  /// 每段标注密度上限（参考掰it 的克制标注，避免满屏高亮）
  final int maxPerParagraph;

  LocalAnnotationEngine({
    required this.masteredWords,
    required this.learningWords,
    required this.bookWords,
    Set<String>? stopwords,
    Set<String>? commonWords,
    Map<String, int>? frequencyRanks,
    this.maxPerParagraph = 8,
  })  : stopwords = stopwords ?? _defaultStopwords,
        commonWords = commonWords ?? const {},
        frequencyRanks = frequencyRanks ?? const {};

  /// 默认停用词表（WebView 原文页选词等外部判定复用，保持口径一致）
  static Set<String> get defaultStopwords => _defaultStopwords;

  static final RegExp _wordRe = RegExp(r"[A-Za-z][A-Za-z'-]*[A-Za-z]|[A-Za-z]{2,}");

  /// 集合命中判定：先查原形，未命中再逐个尝试词形还原候选。
  /// 词书/状态表存原形，正文屈折形式（tests/ran）靠还原后命中。
  static bool _matches(Set<String>? set, String lower) {
    if (set == null || set.isEmpty) return false;
    if (set.contains(lower)) return true;
    for (final c in WordLemmatizer.candidates(lower)) {
      if (set.contains(c)) return true;
    }
    return false;
  }

  /// 判定单个词的标注状态；返回 null 表示不标注
  WordStatus? judge(String word, {Set<String>? savedWords}) {
    final w = word.toLowerCase();
    if (stopwords.contains(w)) return null;
    if (_matches(savedWords, w)) return WordStatus.learning;
    if (_matches(masteredWords, w)) return WordStatus.graduated;
    if (_matches(learningWords, w)) return WordStatus.learning;
    // 常用基础词：即便在当前词书且无进度也不自动标注（用户显式学习中除外，
    // 已在上方 learning/savedWords 分支命中）
    if (_matches(commonWords, w)) return null;
    if (_matches(bookWords, w)) return WordStatus.unfamiliar;
    return null;
  }

  /// 段落 AI 候选预筛：返回可能需要标注的原文词（去重、保持出现顺序）。
  ///
  /// 保守口径：停用词/已收藏/已掌握/学习中/常用词之外的词都是候选——
  /// 词书未学词与不在任何词表的未知词都交给 AI 判断是否值得学。
  /// 只有段落内**全部**词都确定「无需学习」时返回空，阅读页据此
  /// 跳过该段的 AI 请求（此时本地本就不会标任何词，零损失）。
  List<String> aiCandidates(String text, {Set<String>? savedWords}) {
    final out = <String>[];
    final seen = <String>{};
    for (final rm in _wordRe.allMatches(text)) {
      final w = rm.group(0)!.toLowerCase();
      if (stopwords.contains(w)) continue;
      if (_matches(savedWords, w)) continue;
      if (_matches(masteredWords, w)) continue;
      if (_matches(learningWords, w)) continue;
      if (_matches(commonWords, w)) continue;
      if (seen.add(w)) out.add(w);
    }
    return out;
  }

  /// 处理一个纯文本段落，返回 WordSpan 列表。
  ///
  /// [forcedGlosses]：AI 语义分析结果（surface → 语境义），强制标注并
  /// 附带语境义项，支持多词短语（"look forward to"）；单词 surface
  /// 精确匹配失败时按词形还原对齐（AI 返回 test、原文是 tests）。
  /// [savedWords]：本次阅读中已收藏词（lowercase），按 learning 展示。
  /// [skipRanges]：跳过区间（如行内代码，基于 markdown AST 记录），
  /// 区间内的词不做任何标注（含 AI 强制标注）。
  /// 密度上限为**总预算**：AI 强制区间优先占用，本地候选只保留
  /// 剩余名额（带语境义的 AI 词价值高于本地粗标注，优先让位）。
  List<WordSpan> processParagraph(
    String text, {
    Map<String, String> forcedGlosses = const {},
    Set<String> savedWords = const {},
    List<({int start, int end})> skipRanges = const [],
  }) {
    if (text.trim().isEmpty) return [WordSpan(text, WordStatus.graduated)];

    bool skipped(_Match m) =>
        skipRanges.any((r) => m.start < r.end && r.start < m.end);

    // 1. AI 强制标注范围：短语用原文匹配，单词走判定覆盖。
    //    同一 surface 多次出现只标首处（重复括注是视觉噪音且挤占整段预算）；
    //    首处落在跳过区间（如行内代码）时顺延到下一处。
    var forcedRanges = <(_Match, String)>[];
    final seenSurfaces = <String>{};
    for (final entry in forcedGlosses.entries) {
      final surface = entry.key.trim();
      if (surface.isEmpty) continue;
      if (!seenSurfaces.add(surface.toLowerCase())) continue;
      var matches = _findCaseInsensitive(text, surface);
      if (matches.isEmpty && !surface.contains(' ')) {
        matches = _findLemmaMatches(text, surface);
      }
      for (final m in matches) {
        if (skipped(m)) continue;
        forcedRanges.add((m, entry.value));
        break;
      }
    }
    // AI 返回的多个 surface 可能互相嵌套（如 figure 与 figure out）：
    // 重叠区间按「起点靠前、同起点更长优先」去重，否则拼接会输出重复文本，
    // 并连带长按取词偏移错位。
    forcedRanges.sort((a, b) {
      final byStart = a.$1.start.compareTo(b.$1.start);
      if (byStart != 0) return byStart;
      return b.$1.end - a.$1.end;
    });
    final dedupedForced = <(_Match, String)>[];
    for (final f in forcedRanges) {
      if (dedupedForced.any((d) => d.$1.overlaps(f.$1))) continue;
      dedupedForced.add(f);
    }
    forcedRanges = dedupedForced;

    // 2. 常规单词扫描（被 AI 区间覆盖的词标记为占位，由强制区间替代）
    final candidates = <(_Match, WordStatus)>[];
    for (final rm in _wordRe.allMatches(text)) {
      final m = _Match(rm.start, rm.end);
      if (skipped(m)) continue;
      final word = rm.group(0)!;
      var status = judge(word, savedWords: savedWords);
      if (forcedRanges.any((f) => f.$1.overlaps(m))) {
        status = WordStatus.unfamiliar;
      }
      if (status == null || status == WordStatus.graduated) continue;
      candidates.add((m, status));
    }

    // 3. 密度控制：AI 强制区间优先占预算，本地候选只保留剩余名额，
    //    超限时按「unfamiliar > learning、词频越生僻越优先、词长」择优
    final forcedSpan = <int, bool>{};
    for (final f in forcedRanges) {
      for (var i = f.$1.start; i < f.$1.end; i++) {
        forcedSpan[i] = true;
      }
    }
    final budget =
        (maxPerParagraph - forcedRanges.length).clamp(0, maxPerParagraph);
    final kept = <(_Match, WordStatus)>[];
    final free = candidates
        .where((c) => !forcedSpan.containsKey(c.$1.start))
        .toList();
    if (free.length <= budget) {
      kept.addAll(free);
    } else {
      int rarity((_Match, WordStatus) c) {
        final w = text.substring(c.$1.start, c.$1.end).toLowerCase();
        var r = frequencyRanks[w];
        if (r == null) {
          for (final cand in WordLemmatizer.candidates(w)) {
            final hit = frequencyRanks[cand];
            if (hit != null) {
              r = hit;
              break;
            }
          }
        }
        return r == null || r == 0 ? 1 << 30 : r; // 不在频序表=最生僻
      }

      free.sort((a, b) {
        final pa = a.$2 == WordStatus.unfamiliar ? 1 : 0;
        final pb = b.$2 == WordStatus.unfamiliar ? 1 : 0;
        if (pa != pb) return pb - pa;
        final ra = rarity(a), rb = rarity(b);
        if (ra != rb) return rb.compareTo(ra); // 排名数字越大越生僻
        return b.$1.end - b.$1.start - (a.$1.end - a.$1.start);
      });
      kept.addAll(free.take(budget));
    }

    // 4. 合并所有标注区间（短语 > 单词，重叠时先到先得）
    final ranges = <_RangeInfo>[];
    for (final f in forcedRanges) {
      ranges.add(_RangeInfo(f.$1, WordStatus.unfamiliar,
          raw: text.substring(f.$1.start, f.$1.end), gloss: f.$2));
    }
    for (final c in kept) {
      if (forcedSpan.containsKey(c.$1.start)) continue;
      if (ranges.any((r) => r.match.overlaps(c.$1))) continue;
      ranges.add(_RangeInfo(c.$1, c.$2,
          raw: text.substring(c.$1.start, c.$1.end)));
    }
    ranges.sort((a, b) => a.match.start - b.match.start);

    // 5. 拼接输出
    final spans = <WordSpan>[];
    var cursor = 0;
    for (final r in ranges) {
      if (r.match.start > cursor) {
        spans.add(WordSpan(text.substring(cursor, r.match.start), WordStatus.graduated));
      }
      final word = r.raw;
      final glossOverride = r.gloss;
      spans.add(WordSpan(
        word,
        r.status,
        rawWord: word,
        contextGloss: glossOverride,
      ));
      cursor = r.match.end;
    }
    if (cursor < text.length) {
      spans.add(WordSpan(text.substring(cursor), WordStatus.graduated));
    }
    return spans;
  }

  /// 大小写不敏感地查找 [surface] 在 [text] 中的所有出现
  static List<_Match> _findCaseInsensitive(String text, String surface) {
    final escaped = RegExp.escape(surface);
    // 单词级 surface 避免误命中更长单词的子串（如 cat ≠ category）
    final pattern = RegExp(r'\b' + escaped + r'\b', caseSensitive: false);
    return pattern.allMatches(text).map(_Match.fromRegExp).toList();
  }

  /// 词形对齐匹配：AI 返回原形（test）而原文是屈折形式（tests），或反之。
  /// 仅在精确匹配失败时调用，把原文 token 与 surface 的还原候选求交集。
  static List<_Match> _findLemmaMatches(String text, String surface) {
    final target = surface.toLowerCase();
    final variants = {target, ...WordLemmatizer.candidates(target)};
    final out = <_Match>[];
    for (final rm in _wordRe.allMatches(text)) {
      final w = rm.group(0)!.toLowerCase();
      if (w == target) continue; // 精确匹配已查过
      final tokenVariants = {w, ...WordLemmatizer.candidates(w)};
      if (tokenVariants.intersection(variants).isNotEmpty) {
        out.add(_Match(rm.start, rm.end));
      }
    }
    return out;
  }
}

/// 内部区间辅助类
class _Match {
  final int start;
  final int end;
  const _Match(this.start, this.end);
  bool overlaps(_Match other) => start < other.end && other.start < end;
  static _Match fromRegExp(RegExpMatch m) => _Match(m.start, m.end);
}

class _RangeInfo {
  final _Match match;
  final WordStatus status;
  final String raw;
  final String? gloss;
  const _RangeInfo(this.match, this.status, {required this.raw, this.gloss});
}

/// 高频功能词停用表（本地引擎永不标注）
const Set<String> _defaultStopwords = {
  'the', 'a', 'an', 'and', 'or', 'but', 'if', 'then', 'than', 'that', 'this',
  'these', 'those', 'there', 'here', 'of', 'to', 'in', 'on', 'at', 'by', 'for',
  'with', 'about', 'against', 'between', 'into', 'through', 'during', 'before',
  'after', 'above', 'below', 'from', 'up', 'down', 'out', 'off', 'over', 'under',
  'again', 'further', 'once', 'all', 'any', 'both', 'each', 'few', 'more',
  'most', 'other', 'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same',
  'so', 'too', 'very', 'can', 'will', 'just', 'should', 'now', 'is', 'are',
  'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'having', 'do',
  'does', 'did', 'doing', 'would', 'could', 'ought', 'i', 'you', 'he', 'she',
  'it', 'we', 'they', 'them', 'his', 'her', 'its', 'our', 'your', 'my', 'me',
  'him', 'us', 'what', 'which', 'who', 'whom', 'whose', 'when', 'where', 'why',
  'how', 'as', 'because', 'while', 'until', 'since', 'also', 'get', 'got',
  'one', 'two', 'new', 'like', 'make', 'made', 'use', 'used', 'using', 'way',
  'even', 'still', 'back', 'much', 'many', 'may', 'might', 'must', 'shall',
};
