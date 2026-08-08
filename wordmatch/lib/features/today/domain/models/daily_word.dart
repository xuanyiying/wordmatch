/// 每日一词数据模型（来源：高频考点词库）
class DailyWord {
  final String word;
  final String phonetic;
  final String pos;
  final String meaning;
  final String example;
  final String exampleTrans;
  final String source;

  const DailyWord({
    required this.word,
    required this.phonetic,
    required this.pos,
    required this.meaning,
    required this.example,
    required this.exampleTrans,
    required this.source,
  });

  factory DailyWord.fromJson(Map<String, dynamic> json) => DailyWord(
        word: json['word'] as String,
        phonetic: json['phonetic'] as String? ?? '',
        pos: json['pos'] as String? ?? '',
        meaning: json['meaning'] as String? ?? '',
        example: json['example'] as String? ?? '',
        exampleTrans: json['example_trans'] as String? ?? '',
        source: json['source'] as String? ?? '',
      );
}
