/// 每日一句数据模型（来源：经典诗歌、影视剧台词、文学金句）
class DailyQuote {
  final String text;
  final String trans;
  final String work;
  final String author;

  const DailyQuote({
    required this.text,
    required this.trans,
    required this.work,
    required this.author,
  });

  factory DailyQuote.fromJson(Map<String, dynamic> json) => DailyQuote(
        text: json['text'] as String,
        trans: json['trans'] as String? ?? '',
        work: json['work'] as String? ?? '',
        author: json['author'] as String? ?? '',
      );
}
