/// 错词记录模型
class WrongWord {
  final String wordId;
  final String bookId;
  final int wrongCount;
  final DateTime lastWrongAt;

  /// 错误上下文列表（如 "选错了释义"、"选错了单词"）
  final List<String> wrongContexts;

  const WrongWord({
    required this.wordId,
    required this.bookId,
    this.wrongCount = 1,
    required this.lastWrongAt,
    this.wrongContexts = const [],
  });

  WrongWord copyWith({
    String? wordId,
    String? bookId,
    int? wrongCount,
    DateTime? lastWrongAt,
    List<String>? wrongContexts,
  }) =>
      WrongWord(
        wordId: wordId ?? this.wordId,
        bookId: bookId ?? this.bookId,
        wrongCount: wrongCount ?? this.wrongCount,
        lastWrongAt: lastWrongAt ?? this.lastWrongAt,
        wrongContexts: wrongContexts ?? this.wrongContexts,
      );

  /// 从 JSON 反序列化
  factory WrongWord.fromJson(Map<String, dynamic> json) => WrongWord(
        wordId: json['wordId'] as String,
        bookId: json['bookId'] as String,
        wrongCount: json['wrongCount'] as int? ?? 1,
        lastWrongAt: DateTime.parse(json['lastWrongAt'] as String),
        wrongContexts:
            (json['wrongContexts'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  /// 序列化为 JSON
  Map<String, dynamic> toJson() => {
        'wordId': wordId,
        'bookId': bookId,
        'wrongCount': wrongCount,
        'lastWrongAt': lastWrongAt.toIso8601String(),
        'wrongContexts': wrongContexts,
      };
}
