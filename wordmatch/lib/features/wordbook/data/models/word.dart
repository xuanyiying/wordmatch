/// 单词条目
class Word {
  final String id;
  final String word;
  final String? phoneticUs;
  final String? phoneticUk;
  final List<String> definition;
  final String? exampleSentence;
  final int frequency;
  final String bookId;
  final String? rootParts;
  final bool hasMnemonic;

  const Word({
    required this.id,
    required this.word,
    this.phoneticUs,
    this.phoneticUk,
    required this.definition,
    this.exampleSentence,
    this.frequency = 3,
    required this.bookId,
    this.rootParts,
    this.hasMnemonic = false,
  });

  factory Word.fromJson(Map<String, dynamic> json) => Word(
        id: json['id'] as String,
        word: json['word'] as String,
        phoneticUs: json['phonetic_us'] as String?,
        phoneticUk: json['phonetic_uk'] as String?,
        definition: (json['definition'] as List<dynamic>).cast<String>(),
        exampleSentence: json['example'] as String?,
        frequency: json['frequency'] as int? ?? 3,
        bookId: json['book_id'] as String,
        rootParts: json['root_parts'] as String?,
        hasMnemonic: json['has_mnemonic'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'phonetic_us': phoneticUs,
        'phonetic_uk': phoneticUk,
        'definition': definition,
        'example': exampleSentence,
        'frequency': frequency,
        'book_id': bookId,
        'root_parts': rootParts,
        'has_mnemonic': hasMnemonic,
      };
}
