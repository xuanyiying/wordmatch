import 'package:flutter/material.dart';

import '../../domain/services/annotation_models.dart';

/// 标注段落渲染结果。
///
/// [renderToSource] 把**渲染文本缓冲区**的每个字符索引映射回原文索引，
/// 供长按手势定位单词。渲染缓冲区与 RenderParagraph 的取词偏移严格对齐：
/// 普通 TextSpan 逐字符映射；标注词以 WidgetSpan 整体渲染（词 + 划线下方
/// 括注），在缓冲区中只占 1 个占位符字符（U+FFFC），映射到该词/短语的
/// 原文起始位置。
class AnnotatedParagraph {
  final TextSpan root;
  final List<int> renderToSource;

  /// 占位符渲染偏移 → 所属标注词/短语原形（短语整体取词，不拆单词）
  final Map<int, String> placeholderWords;

  /// 该段被标注的词（lowercase，供调用方做定向缓存失效）
  final Set<String> words;

  const AnnotatedParagraph({
    required this.root,
    required this.renderToSource,
    this.placeholderWords = const {},
    this.words = const {},
  });

  /// 单词（含 a/I 等单字母词）；撇号在词内时整体匹配（don't）
  static final RegExp _wordRe =
      RegExp(r"[A-Za-z](?:[A-Za-z'-]*[A-Za-z])?");

  /// 渲染字符索引 → 原文中被按住的单词；括注占位符直接命中所属标注词。
  /// 命中间隔/标点时做 1 字符容错；落在无词区域返回 null。
  String? wordAtRenderOffset(String sourceText, int renderOffset) {
    if (renderToSource.isEmpty) return null;
    final ro = renderOffset.clamp(0, renderToSource.length - 1);
    // 精确按在 WidgetSpan 占位符上：返回完整词/短语（如 look forward to）
    final placeholder = placeholderWords[ro];
    if (placeholder != null && placeholder.isNotEmpty) return placeholder;

    final src = renderToSource[ro];
    if (src < 0 || src >= sourceText.length) return null;
    for (final m in _wordRe.allMatches(sourceText)) {
      if (src >= m.start - 1 && src <= m.end) return m.group(0)!;
      if (m.start > src + 1) break;
    }
    return null;
  }
}

/// 把 [WordSpan] 列表渲染成带标注样式的 InlineSpan 列表：
/// - unfamiliar：红色点状下划线 + 红色语境括注（生词）
/// - learning：蓝紫点状下划线 + 蓝紫语境括注（学习中/已收藏）
/// - graduated：无标注
///
/// 括注不再行内跟排，而是占布局空间显示在划线正下方（词在上、释义在下，
/// 所在行自动撑高，不与正文重叠）；点击标注词弹卡（音标/例句/收藏），
/// 长按由调用方在外层 GestureDetector 配合 [AnnotatedParagraph] 实现。
/// BaiitMobile 同款色板：indigo #6366F1 / red #EF4444，下划线 0.6 透明度、
/// 括注同色系 0.9 透明度。
const _learningUnderline = Color.fromRGBO(99, 102, 241, 0.6);
const _learningGloss = Color.fromRGBO(99, 102, 241, 0.9);
const _unfamiliarUnderline = Color.fromRGBO(239, 68, 68, 0.6);
const _unfamiliarGloss = Color.fromRGBO(239, 68, 68, 0.9);

AnnotatedParagraph buildAnnotatedParagraph(
  List<WordSpan> spans, {
  required TextStyle base,
  required void Function(String word) onTap,
}) {
  final children = <InlineSpan>[];
  final renderToSource = <int>[];
  final placeholderWords = <int, String>{};
  var src = 0;

  for (final s in spans) {
    if (!s.isAnnotated) {
      // 普通文本：逐字符映射渲染偏移 → 原文偏移
      for (var i = 0; i < s.text.length; i++) {
        renderToSource.add(src + i);
      }
      children.add(TextSpan(text: s.text, style: base));
      src += s.text.length;
      continue;
    }

    // 标注词/短语由 WidgetSpan 子组件渲染（词 + 下方括注），在段落文本
    // 缓冲区中只占 1 个占位符字符；只登记 1 条映射指向词首原文索引。
    // 切勿按 s.text.length 登记——词文不在段落缓冲区内，多登记会让后续
    // 所有字符的取词偏移累积错位（按到后一个词却弹出前一个词）。
    placeholderWords[renderToSource.length] = s.rawWord;
    renderToSource.add(src);

    final isUnfamiliar = s.status == WordStatus.unfamiliar;
    final gloss = s.contextGloss;

    final wordStyle = base.copyWith(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: isUnfamiliar ? _unfamiliarUnderline : _learningUnderline,
      decorationThickness: 2,
    );

    final glossStyle = base.copyWith(
      fontSize: base.fontSize != null ? base.fontSize! - 5 : 10,
      height: 1.2,
      color: isUnfamiliar ? _unfamiliarGloss : _learningGloss,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.w500,
    );

    children.add(WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(s.rawWord),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.text, style: wordStyle),
            if (gloss != null && gloss.isNotEmpty)
              Text(
                gloss,
                style: glossStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    ));
    src += s.text.length;
  }

  return AnnotatedParagraph(
    root: TextSpan(children: children),
    renderToSource: renderToSource,
    placeholderWords: placeholderWords,
    words: {
      for (final s in spans)
        if (s.isAnnotated) s.rawWord.toLowerCase(),
    },
  );
}
