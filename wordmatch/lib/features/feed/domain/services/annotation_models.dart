/// 划词标注数据模型
///
/// 三级状态（参考浏览器插件"掰it"）：
/// - graduated：已掌握，无标注
/// - learning：学习中，蓝紫点状下划线
/// - unfamiliar：生词，红色点状下划线
enum WordStatus { graduated, learning, unfamiliar }

/// 文本片段：要么是普通文本（status=graduated 且 rawWord 为空），
/// 要么是一个被标注的单词/短语（rawWord 非空）。
class WordSpan {
  /// 展示文本（原文片段）
  final String text;

  /// 标注状态
  final WordStatus status;

  /// 被标注的词/短语原形（未标注文本为空串）
  final String rawWord;

  /// AI 语境语义分析给出的语境义项（如 "gloss over" → "敷衍，一笔带过"）
  final String? contextGloss;

  const WordSpan(this.text, this.status, {this.rawWord = '', this.contextGloss});

  bool get isAnnotated => rawWord.isNotEmpty;
}

/// AI 语义分析返回的单个标注 token（词或短语）
class SemanticToken {
  /// 原文表面形式（与原文做大小写不敏感匹配）
  final String surface;

  /// 语境义项（中文短释义）
  final String gloss;

  /// 是否短语/习语（整体标注）
  final bool phrase;

  const SemanticToken({
    required this.surface,
    required this.gloss,
    this.phrase = false,
  });

  factory SemanticToken.fromJson(Map<String, dynamic> j) => SemanticToken(
        surface: (j['t'] as String?)?.trim() ?? '',
        gloss: (j['g'] as String?)?.trim() ?? '',
        phrase: j['phrase'] == true,
      );

  Map<String, dynamic> toJson() =>
      {'t': surface, 'g': gloss, 'phrase': phrase};
}

/// 单个段落的 AI 语义标注结果
class ParagraphAnnotation {
  /// 段落序号（与阅读页 prose 段落列表对齐）
  final int paragraphIndex;
  final List<SemanticToken> tokens;

  const ParagraphAnnotation({
    required this.paragraphIndex,
    required this.tokens,
  });

  factory ParagraphAnnotation.fromJson(Map<String, dynamic> j) {
    final p = j['p'];
    final index = p is int
        ? p
        : int.tryParse(p?.toString() ?? '') ?? 0;
    return ParagraphAnnotation(
      paragraphIndex: index,
      tokens: ((j['items'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SemanticToken.fromJson)
          .where((t) => t.surface.isNotEmpty)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'p': paragraphIndex,
        'items': tokens.map((t) => t.toJson()).toList(),
      };
}

/// 整篇文章的语义标注结果（按段落）
class SemanticResult {
  final List<ParagraphAnnotation> paragraphs;

  const SemanticResult(this.paragraphs);

  Map<int, List<SemanticToken>> get byParagraph => {
        for (final p in paragraphs) p.paragraphIndex: p.tokens,
      };

  factory SemanticResult.fromJson(Map<String, dynamic> j) => SemanticResult(
        ((j['paragraphs'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ParagraphAnnotation.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'paragraphs': paragraphs.map((p) => p.toJson()).toList(),
      };
}
