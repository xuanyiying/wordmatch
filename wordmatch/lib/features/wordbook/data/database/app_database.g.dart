// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WordsTable extends Words with TableInfo<$WordsTable, Word> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
      'word', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneticUsMeta =
      const VerificationMeta('phoneticUs');
  @override
  late final GeneratedColumn<String> phoneticUs = GeneratedColumn<String>(
      'phonetic_us', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneticUkMeta =
      const VerificationMeta('phoneticUk');
  @override
  late final GeneratedColumn<String> phoneticUk = GeneratedColumn<String>(
      'phonetic_uk', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _definitionMeta =
      const VerificationMeta('definition');
  @override
  late final GeneratedColumn<String> definition = GeneratedColumn<String>(
      'definition', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exampleSentenceMeta =
      const VerificationMeta('exampleSentence');
  @override
  late final GeneratedColumn<String> exampleSentence = GeneratedColumn<String>(
      'example_sentence', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _frequencyMeta =
      const VerificationMeta('frequency');
  @override
  late final GeneratedColumn<int> frequency = GeneratedColumn<int>(
      'frequency', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rootPartsMeta =
      const VerificationMeta('rootParts');
  @override
  late final GeneratedColumn<String> rootParts = GeneratedColumn<String>(
      'root_parts', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hasMnemonicMeta =
      const VerificationMeta('hasMnemonic');
  @override
  late final GeneratedColumn<bool> hasMnemonic = GeneratedColumn<bool>(
      'has_mnemonic', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_mnemonic" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        word,
        phoneticUs,
        phoneticUk,
        definition,
        exampleSentence,
        frequency,
        bookId,
        rootParts,
        hasMnemonic,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(Insertable<Word> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
          _wordMeta, word.isAcceptableOrUnknown(data['word']!, _wordMeta));
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('phonetic_us')) {
      context.handle(
          _phoneticUsMeta,
          phoneticUs.isAcceptableOrUnknown(
              data['phonetic_us']!, _phoneticUsMeta));
    }
    if (data.containsKey('phonetic_uk')) {
      context.handle(
          _phoneticUkMeta,
          phoneticUk.isAcceptableOrUnknown(
              data['phonetic_uk']!, _phoneticUkMeta));
    }
    if (data.containsKey('definition')) {
      context.handle(
          _definitionMeta,
          definition.isAcceptableOrUnknown(
              data['definition']!, _definitionMeta));
    } else if (isInserting) {
      context.missing(_definitionMeta);
    }
    if (data.containsKey('example_sentence')) {
      context.handle(
          _exampleSentenceMeta,
          exampleSentence.isAcceptableOrUnknown(
              data['example_sentence']!, _exampleSentenceMeta));
    }
    if (data.containsKey('frequency')) {
      context.handle(_frequencyMeta,
          frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('root_parts')) {
      context.handle(_rootPartsMeta,
          rootParts.isAcceptableOrUnknown(data['root_parts']!, _rootPartsMeta));
    }
    if (data.containsKey('has_mnemonic')) {
      context.handle(
          _hasMnemonicMeta,
          hasMnemonic.isAcceptableOrUnknown(
              data['has_mnemonic']!, _hasMnemonicMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Word(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      word: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word'])!,
      phoneticUs: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phonetic_us']),
      phoneticUk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phonetic_uk']),
      definition: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}definition'])!,
      exampleSentence: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}example_sentence']),
      frequency: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}frequency'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      rootParts: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}root_parts']),
      hasMnemonic: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_mnemonic'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class Word extends DataClass implements Insertable<Word> {
  /// 单词唯一ID
  final String id;

  /// 单词文本
  final String word;

  /// 美式音标
  final String? phoneticUs;

  /// 英式音标
  final String? phoneticUk;

  /// 释义（JSON 数组格式）
  final String definition;

  /// 例句
  final String? exampleSentence;

  /// 词频等级 (1-5)
  final int frequency;

  /// 所属词书ID
  final String bookId;

  /// 词根拆分
  final String? rootParts;

  /// 是否有记忆技巧
  final bool hasMnemonic;

  /// 创建时间
  final DateTime createdAt;
  const Word(
      {required this.id,
      required this.word,
      this.phoneticUs,
      this.phoneticUk,
      required this.definition,
      this.exampleSentence,
      required this.frequency,
      required this.bookId,
      this.rootParts,
      required this.hasMnemonic,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['word'] = Variable<String>(word);
    if (!nullToAbsent || phoneticUs != null) {
      map['phonetic_us'] = Variable<String>(phoneticUs);
    }
    if (!nullToAbsent || phoneticUk != null) {
      map['phonetic_uk'] = Variable<String>(phoneticUk);
    }
    map['definition'] = Variable<String>(definition);
    if (!nullToAbsent || exampleSentence != null) {
      map['example_sentence'] = Variable<String>(exampleSentence);
    }
    map['frequency'] = Variable<int>(frequency);
    map['book_id'] = Variable<String>(bookId);
    if (!nullToAbsent || rootParts != null) {
      map['root_parts'] = Variable<String>(rootParts);
    }
    map['has_mnemonic'] = Variable<bool>(hasMnemonic);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      word: Value(word),
      phoneticUs: phoneticUs == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneticUs),
      phoneticUk: phoneticUk == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneticUk),
      definition: Value(definition),
      exampleSentence: exampleSentence == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleSentence),
      frequency: Value(frequency),
      bookId: Value(bookId),
      rootParts: rootParts == null && nullToAbsent
          ? const Value.absent()
          : Value(rootParts),
      hasMnemonic: Value(hasMnemonic),
      createdAt: Value(createdAt),
    );
  }

  factory Word.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      id: serializer.fromJson<String>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      phoneticUs: serializer.fromJson<String?>(json['phoneticUs']),
      phoneticUk: serializer.fromJson<String?>(json['phoneticUk']),
      definition: serializer.fromJson<String>(json['definition']),
      exampleSentence: serializer.fromJson<String?>(json['exampleSentence']),
      frequency: serializer.fromJson<int>(json['frequency']),
      bookId: serializer.fromJson<String>(json['bookId']),
      rootParts: serializer.fromJson<String?>(json['rootParts']),
      hasMnemonic: serializer.fromJson<bool>(json['hasMnemonic']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'word': serializer.toJson<String>(word),
      'phoneticUs': serializer.toJson<String?>(phoneticUs),
      'phoneticUk': serializer.toJson<String?>(phoneticUk),
      'definition': serializer.toJson<String>(definition),
      'exampleSentence': serializer.toJson<String?>(exampleSentence),
      'frequency': serializer.toJson<int>(frequency),
      'bookId': serializer.toJson<String>(bookId),
      'rootParts': serializer.toJson<String?>(rootParts),
      'hasMnemonic': serializer.toJson<bool>(hasMnemonic),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Word copyWith(
          {String? id,
          String? word,
          Value<String?> phoneticUs = const Value.absent(),
          Value<String?> phoneticUk = const Value.absent(),
          String? definition,
          Value<String?> exampleSentence = const Value.absent(),
          int? frequency,
          String? bookId,
          Value<String?> rootParts = const Value.absent(),
          bool? hasMnemonic,
          DateTime? createdAt}) =>
      Word(
        id: id ?? this.id,
        word: word ?? this.word,
        phoneticUs: phoneticUs.present ? phoneticUs.value : this.phoneticUs,
        phoneticUk: phoneticUk.present ? phoneticUk.value : this.phoneticUk,
        definition: definition ?? this.definition,
        exampleSentence: exampleSentence.present
            ? exampleSentence.value
            : this.exampleSentence,
        frequency: frequency ?? this.frequency,
        bookId: bookId ?? this.bookId,
        rootParts: rootParts.present ? rootParts.value : this.rootParts,
        hasMnemonic: hasMnemonic ?? this.hasMnemonic,
        createdAt: createdAt ?? this.createdAt,
      );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      phoneticUs:
          data.phoneticUs.present ? data.phoneticUs.value : this.phoneticUs,
      phoneticUk:
          data.phoneticUk.present ? data.phoneticUk.value : this.phoneticUk,
      definition:
          data.definition.present ? data.definition.value : this.definition,
      exampleSentence: data.exampleSentence.present
          ? data.exampleSentence.value
          : this.exampleSentence,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      rootParts: data.rootParts.present ? data.rootParts.value : this.rootParts,
      hasMnemonic:
          data.hasMnemonic.present ? data.hasMnemonic.value : this.hasMnemonic,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('phoneticUs: $phoneticUs, ')
          ..write('phoneticUk: $phoneticUk, ')
          ..write('definition: $definition, ')
          ..write('exampleSentence: $exampleSentence, ')
          ..write('frequency: $frequency, ')
          ..write('bookId: $bookId, ')
          ..write('rootParts: $rootParts, ')
          ..write('hasMnemonic: $hasMnemonic, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, word, phoneticUs, phoneticUk, definition,
      exampleSentence, frequency, bookId, rootParts, hasMnemonic, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.id == this.id &&
          other.word == this.word &&
          other.phoneticUs == this.phoneticUs &&
          other.phoneticUk == this.phoneticUk &&
          other.definition == this.definition &&
          other.exampleSentence == this.exampleSentence &&
          other.frequency == this.frequency &&
          other.bookId == this.bookId &&
          other.rootParts == this.rootParts &&
          other.hasMnemonic == this.hasMnemonic &&
          other.createdAt == this.createdAt);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<String> id;
  final Value<String> word;
  final Value<String?> phoneticUs;
  final Value<String?> phoneticUk;
  final Value<String> definition;
  final Value<String?> exampleSentence;
  final Value<int> frequency;
  final Value<String> bookId;
  final Value<String?> rootParts;
  final Value<bool> hasMnemonic;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.phoneticUs = const Value.absent(),
    this.phoneticUk = const Value.absent(),
    this.definition = const Value.absent(),
    this.exampleSentence = const Value.absent(),
    this.frequency = const Value.absent(),
    this.bookId = const Value.absent(),
    this.rootParts = const Value.absent(),
    this.hasMnemonic = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordsCompanion.insert({
    required String id,
    required String word,
    this.phoneticUs = const Value.absent(),
    this.phoneticUk = const Value.absent(),
    required String definition,
    this.exampleSentence = const Value.absent(),
    this.frequency = const Value.absent(),
    required String bookId,
    this.rootParts = const Value.absent(),
    this.hasMnemonic = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        word = Value(word),
        definition = Value(definition),
        bookId = Value(bookId);
  static Insertable<Word> custom({
    Expression<String>? id,
    Expression<String>? word,
    Expression<String>? phoneticUs,
    Expression<String>? phoneticUk,
    Expression<String>? definition,
    Expression<String>? exampleSentence,
    Expression<int>? frequency,
    Expression<String>? bookId,
    Expression<String>? rootParts,
    Expression<bool>? hasMnemonic,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (phoneticUs != null) 'phonetic_us': phoneticUs,
      if (phoneticUk != null) 'phonetic_uk': phoneticUk,
      if (definition != null) 'definition': definition,
      if (exampleSentence != null) 'example_sentence': exampleSentence,
      if (frequency != null) 'frequency': frequency,
      if (bookId != null) 'book_id': bookId,
      if (rootParts != null) 'root_parts': rootParts,
      if (hasMnemonic != null) 'has_mnemonic': hasMnemonic,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordsCompanion copyWith(
      {Value<String>? id,
      Value<String>? word,
      Value<String?>? phoneticUs,
      Value<String?>? phoneticUk,
      Value<String>? definition,
      Value<String?>? exampleSentence,
      Value<int>? frequency,
      Value<String>? bookId,
      Value<String?>? rootParts,
      Value<bool>? hasMnemonic,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return WordsCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      phoneticUs: phoneticUs ?? this.phoneticUs,
      phoneticUk: phoneticUk ?? this.phoneticUk,
      definition: definition ?? this.definition,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      frequency: frequency ?? this.frequency,
      bookId: bookId ?? this.bookId,
      rootParts: rootParts ?? this.rootParts,
      hasMnemonic: hasMnemonic ?? this.hasMnemonic,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (phoneticUs.present) {
      map['phonetic_us'] = Variable<String>(phoneticUs.value);
    }
    if (phoneticUk.present) {
      map['phonetic_uk'] = Variable<String>(phoneticUk.value);
    }
    if (definition.present) {
      map['definition'] = Variable<String>(definition.value);
    }
    if (exampleSentence.present) {
      map['example_sentence'] = Variable<String>(exampleSentence.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<int>(frequency.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (rootParts.present) {
      map['root_parts'] = Variable<String>(rootParts.value);
    }
    if (hasMnemonic.present) {
      map['has_mnemonic'] = Variable<bool>(hasMnemonic.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('phoneticUs: $phoneticUs, ')
          ..write('phoneticUk: $phoneticUk, ')
          ..write('definition: $definition, ')
          ..write('exampleSentence: $exampleSentence, ')
          ..write('frequency: $frequency, ')
          ..write('bookId: $bookId, ')
          ..write('rootParts: $rootParts, ')
          ..write('hasMnemonic: $hasMnemonic, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserWordProgressTable extends UserWordProgress
    with TableInfo<$UserWordProgressTable, UserWordProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserWordProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
      'word_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _easinessFactorMeta =
      const VerificationMeta('easinessFactor');
  @override
  late final GeneratedColumn<double> easinessFactor = GeneratedColumn<double>(
      'easiness_factor', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(2.5));
  static const VerificationMeta _intervalDaysMeta =
      const VerificationMeta('intervalDays');
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
      'interval_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _repetitionsMeta =
      const VerificationMeta('repetitions');
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
      'repetitions', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextReviewDateMeta =
      const VerificationMeta('nextReviewDate');
  @override
  late final GeneratedColumn<DateTime> nextReviewDate =
      GeneratedColumn<DateTime>('next_review_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastQualityMeta =
      const VerificationMeta('lastQuality');
  @override
  late final GeneratedColumn<int> lastQuality = GeneratedColumn<int>(
      'last_quality', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isMasteredMeta =
      const VerificationMeta('isMastered');
  @override
  late final GeneratedColumn<bool> isMastered = GeneratedColumn<bool>(
      'is_mastered', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_mastered" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _reviewDebtMeta =
      const VerificationMeta('reviewDebt');
  @override
  late final GeneratedColumn<int> reviewDebt = GeneratedColumn<int>(
      'review_debt', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        wordId,
        bookId,
        easinessFactor,
        intervalDays,
        repetitions,
        nextReviewDate,
        lastQuality,
        isMastered,
        reviewDebt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_word_progress';
  @override
  VerificationContext validateIntegrity(
      Insertable<UserWordProgressData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('easiness_factor')) {
      context.handle(
          _easinessFactorMeta,
          easinessFactor.isAcceptableOrUnknown(
              data['easiness_factor']!, _easinessFactorMeta));
    }
    if (data.containsKey('interval_days')) {
      context.handle(
          _intervalDaysMeta,
          intervalDays.isAcceptableOrUnknown(
              data['interval_days']!, _intervalDaysMeta));
    }
    if (data.containsKey('repetitions')) {
      context.handle(
          _repetitionsMeta,
          repetitions.isAcceptableOrUnknown(
              data['repetitions']!, _repetitionsMeta));
    }
    if (data.containsKey('next_review_date')) {
      context.handle(
          _nextReviewDateMeta,
          nextReviewDate.isAcceptableOrUnknown(
              data['next_review_date']!, _nextReviewDateMeta));
    } else if (isInserting) {
      context.missing(_nextReviewDateMeta);
    }
    if (data.containsKey('last_quality')) {
      context.handle(
          _lastQualityMeta,
          lastQuality.isAcceptableOrUnknown(
              data['last_quality']!, _lastQualityMeta));
    }
    if (data.containsKey('is_mastered')) {
      context.handle(
          _isMasteredMeta,
          isMastered.isAcceptableOrUnknown(
              data['is_mastered']!, _isMasteredMeta));
    }
    if (data.containsKey('review_debt')) {
      context.handle(
          _reviewDebtMeta,
          reviewDebt.isAcceptableOrUnknown(
              data['review_debt']!, _reviewDebtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  UserWordProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserWordProgressData(
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word_id'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      easinessFactor: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}easiness_factor'])!,
      intervalDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}interval_days'])!,
      repetitions: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}repetitions'])!,
      nextReviewDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_review_date'])!,
      lastQuality: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_quality'])!,
      isMastered: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_mastered'])!,
      reviewDebt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}review_debt'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UserWordProgressTable createAlias(String alias) {
    return $UserWordProgressTable(attachedDatabase, alias);
  }
}

class UserWordProgressData extends DataClass
    implements Insertable<UserWordProgressData> {
  /// 单词ID
  final String wordId;

  /// 词书ID
  final String bookId;

  /// 难度因子 (SM-2算法)
  final double easinessFactor;

  /// 复习间隔天数
  final int intervalDays;

  /// 复习次数
  final int repetitions;

  /// 下次复习日期
  final DateTime nextReviewDate;

  /// 最近一次质量评分 (0-5)
  final int lastQuality;

  /// 是否已掌握
  final bool isMastered;

  /// 复习债务
  final int reviewDebt;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;
  const UserWordProgressData(
      {required this.wordId,
      required this.bookId,
      required this.easinessFactor,
      required this.intervalDays,
      required this.repetitions,
      required this.nextReviewDate,
      required this.lastQuality,
      required this.isMastered,
      required this.reviewDebt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<String>(wordId);
    map['book_id'] = Variable<String>(bookId);
    map['easiness_factor'] = Variable<double>(easinessFactor);
    map['interval_days'] = Variable<int>(intervalDays);
    map['repetitions'] = Variable<int>(repetitions);
    map['next_review_date'] = Variable<DateTime>(nextReviewDate);
    map['last_quality'] = Variable<int>(lastQuality);
    map['is_mastered'] = Variable<bool>(isMastered);
    map['review_debt'] = Variable<int>(reviewDebt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserWordProgressCompanion toCompanion(bool nullToAbsent) {
    return UserWordProgressCompanion(
      wordId: Value(wordId),
      bookId: Value(bookId),
      easinessFactor: Value(easinessFactor),
      intervalDays: Value(intervalDays),
      repetitions: Value(repetitions),
      nextReviewDate: Value(nextReviewDate),
      lastQuality: Value(lastQuality),
      isMastered: Value(isMastered),
      reviewDebt: Value(reviewDebt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserWordProgressData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserWordProgressData(
      wordId: serializer.fromJson<String>(json['wordId']),
      bookId: serializer.fromJson<String>(json['bookId']),
      easinessFactor: serializer.fromJson<double>(json['easinessFactor']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      nextReviewDate: serializer.fromJson<DateTime>(json['nextReviewDate']),
      lastQuality: serializer.fromJson<int>(json['lastQuality']),
      isMastered: serializer.fromJson<bool>(json['isMastered']),
      reviewDebt: serializer.fromJson<int>(json['reviewDebt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<String>(wordId),
      'bookId': serializer.toJson<String>(bookId),
      'easinessFactor': serializer.toJson<double>(easinessFactor),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'repetitions': serializer.toJson<int>(repetitions),
      'nextReviewDate': serializer.toJson<DateTime>(nextReviewDate),
      'lastQuality': serializer.toJson<int>(lastQuality),
      'isMastered': serializer.toJson<bool>(isMastered),
      'reviewDebt': serializer.toJson<int>(reviewDebt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserWordProgressData copyWith(
          {String? wordId,
          String? bookId,
          double? easinessFactor,
          int? intervalDays,
          int? repetitions,
          DateTime? nextReviewDate,
          int? lastQuality,
          bool? isMastered,
          int? reviewDebt,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      UserWordProgressData(
        wordId: wordId ?? this.wordId,
        bookId: bookId ?? this.bookId,
        easinessFactor: easinessFactor ?? this.easinessFactor,
        intervalDays: intervalDays ?? this.intervalDays,
        repetitions: repetitions ?? this.repetitions,
        nextReviewDate: nextReviewDate ?? this.nextReviewDate,
        lastQuality: lastQuality ?? this.lastQuality,
        isMastered: isMastered ?? this.isMastered,
        reviewDebt: reviewDebt ?? this.reviewDebt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  UserWordProgressData copyWithCompanion(UserWordProgressCompanion data) {
    return UserWordProgressData(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      easinessFactor: data.easinessFactor.present
          ? data.easinessFactor.value
          : this.easinessFactor,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      repetitions:
          data.repetitions.present ? data.repetitions.value : this.repetitions,
      nextReviewDate: data.nextReviewDate.present
          ? data.nextReviewDate.value
          : this.nextReviewDate,
      lastQuality:
          data.lastQuality.present ? data.lastQuality.value : this.lastQuality,
      isMastered:
          data.isMastered.present ? data.isMastered.value : this.isMastered,
      reviewDebt:
          data.reviewDebt.present ? data.reviewDebt.value : this.reviewDebt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserWordProgressData(')
          ..write('wordId: $wordId, ')
          ..write('bookId: $bookId, ')
          ..write('easinessFactor: $easinessFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('nextReviewDate: $nextReviewDate, ')
          ..write('lastQuality: $lastQuality, ')
          ..write('isMastered: $isMastered, ')
          ..write('reviewDebt: $reviewDebt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      wordId,
      bookId,
      easinessFactor,
      intervalDays,
      repetitions,
      nextReviewDate,
      lastQuality,
      isMastered,
      reviewDebt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserWordProgressData &&
          other.wordId == this.wordId &&
          other.bookId == this.bookId &&
          other.easinessFactor == this.easinessFactor &&
          other.intervalDays == this.intervalDays &&
          other.repetitions == this.repetitions &&
          other.nextReviewDate == this.nextReviewDate &&
          other.lastQuality == this.lastQuality &&
          other.isMastered == this.isMastered &&
          other.reviewDebt == this.reviewDebt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserWordProgressCompanion extends UpdateCompanion<UserWordProgressData> {
  final Value<String> wordId;
  final Value<String> bookId;
  final Value<double> easinessFactor;
  final Value<int> intervalDays;
  final Value<int> repetitions;
  final Value<DateTime> nextReviewDate;
  final Value<int> lastQuality;
  final Value<bool> isMastered;
  final Value<int> reviewDebt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserWordProgressCompanion({
    this.wordId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.easinessFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.nextReviewDate = const Value.absent(),
    this.lastQuality = const Value.absent(),
    this.isMastered = const Value.absent(),
    this.reviewDebt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserWordProgressCompanion.insert({
    required String wordId,
    required String bookId,
    this.easinessFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    required DateTime nextReviewDate,
    this.lastQuality = const Value.absent(),
    this.isMastered = const Value.absent(),
    this.reviewDebt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : wordId = Value(wordId),
        bookId = Value(bookId),
        nextReviewDate = Value(nextReviewDate);
  static Insertable<UserWordProgressData> custom({
    Expression<String>? wordId,
    Expression<String>? bookId,
    Expression<double>? easinessFactor,
    Expression<int>? intervalDays,
    Expression<int>? repetitions,
    Expression<DateTime>? nextReviewDate,
    Expression<int>? lastQuality,
    Expression<bool>? isMastered,
    Expression<int>? reviewDebt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (bookId != null) 'book_id': bookId,
      if (easinessFactor != null) 'easiness_factor': easinessFactor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (repetitions != null) 'repetitions': repetitions,
      if (nextReviewDate != null) 'next_review_date': nextReviewDate,
      if (lastQuality != null) 'last_quality': lastQuality,
      if (isMastered != null) 'is_mastered': isMastered,
      if (reviewDebt != null) 'review_debt': reviewDebt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserWordProgressCompanion copyWith(
      {Value<String>? wordId,
      Value<String>? bookId,
      Value<double>? easinessFactor,
      Value<int>? intervalDays,
      Value<int>? repetitions,
      Value<DateTime>? nextReviewDate,
      Value<int>? lastQuality,
      Value<bool>? isMastered,
      Value<int>? reviewDebt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return UserWordProgressCompanion(
      wordId: wordId ?? this.wordId,
      bookId: bookId ?? this.bookId,
      easinessFactor: easinessFactor ?? this.easinessFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastQuality: lastQuality ?? this.lastQuality,
      isMastered: isMastered ?? this.isMastered,
      reviewDebt: reviewDebt ?? this.reviewDebt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (easinessFactor.present) {
      map['easiness_factor'] = Variable<double>(easinessFactor.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (nextReviewDate.present) {
      map['next_review_date'] = Variable<DateTime>(nextReviewDate.value);
    }
    if (lastQuality.present) {
      map['last_quality'] = Variable<int>(lastQuality.value);
    }
    if (isMastered.present) {
      map['is_mastered'] = Variable<bool>(isMastered.value);
    }
    if (reviewDebt.present) {
      map['review_debt'] = Variable<int>(reviewDebt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserWordProgressCompanion(')
          ..write('wordId: $wordId, ')
          ..write('bookId: $bookId, ')
          ..write('easinessFactor: $easinessFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('nextReviewDate: $nextReviewDate, ')
          ..write('lastQuality: $lastQuality, ')
          ..write('isMastered: $isMastered, ')
          ..write('reviewDebt: $reviewDebt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GameSessionsTable extends GameSessions
    with TableInfo<$GameSessionsTable, GameSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _domainIdMeta =
      const VerificationMeta('domainId');
  @override
  late final GeneratedColumn<String> domainId = GeneratedColumn<String>(
      'domain_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _gameModeMeta =
      const VerificationMeta('gameMode');
  @override
  late final GeneratedColumn<String> gameMode = GeneratedColumn<String>(
      'game_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('word'));
  static const VerificationMeta _gridSizeMeta =
      const VerificationMeta('gridSize');
  @override
  late final GeneratedColumn<int> gridSize = GeneratedColumn<int>(
      'grid_size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _matchCountMeta =
      const VerificationMeta('matchCount');
  @override
  late final GeneratedColumn<int> matchCount = GeneratedColumn<int>(
      'match_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _errorCountMeta =
      const VerificationMeta('errorCount');
  @override
  late final GeneratedColumn<int> errorCount = GeneratedColumn<int>(
      'error_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _hintCountMeta =
      const VerificationMeta('hintCount');
  @override
  late final GeneratedColumn<int> hintCount = GeneratedColumn<int>(
      'hint_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _maxComboMeta =
      const VerificationMeta('maxCombo');
  @override
  late final GeneratedColumn<int> maxCombo = GeneratedColumn<int>(
      'max_combo', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
      'score', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        bookId,
        domainId,
        gameMode,
        gridSize,
        matchCount,
        errorCount,
        hintCount,
        durationMs,
        maxCombo,
        score,
        isCompleted,
        startTime,
        endTime,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<GameSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('domain_id')) {
      context.handle(_domainIdMeta,
          domainId.isAcceptableOrUnknown(data['domain_id']!, _domainIdMeta));
    }
    if (data.containsKey('game_mode')) {
      context.handle(_gameModeMeta,
          gameMode.isAcceptableOrUnknown(data['game_mode']!, _gameModeMeta));
    }
    if (data.containsKey('grid_size')) {
      context.handle(_gridSizeMeta,
          gridSize.isAcceptableOrUnknown(data['grid_size']!, _gridSizeMeta));
    } else if (isInserting) {
      context.missing(_gridSizeMeta);
    }
    if (data.containsKey('match_count')) {
      context.handle(
          _matchCountMeta,
          matchCount.isAcceptableOrUnknown(
              data['match_count']!, _matchCountMeta));
    }
    if (data.containsKey('error_count')) {
      context.handle(
          _errorCountMeta,
          errorCount.isAcceptableOrUnknown(
              data['error_count']!, _errorCountMeta));
    }
    if (data.containsKey('hint_count')) {
      context.handle(_hintCountMeta,
          hintCount.isAcceptableOrUnknown(data['hint_count']!, _hintCountMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('max_combo')) {
      context.handle(_maxComboMeta,
          maxCombo.isAcceptableOrUnknown(data['max_combo']!, _maxComboMeta));
    }
    if (data.containsKey('score')) {
      context.handle(
          _scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GameSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      domainId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}domain_id']),
      gameMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}game_mode'])!,
      gridSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}grid_size'])!,
      matchCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}match_count'])!,
      errorCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}error_count'])!,
      hintCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hint_count'])!,
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      maxCombo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_combo'])!,
      score: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}score'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $GameSessionsTable createAlias(String alias) {
    return $GameSessionsTable(attachedDatabase, alias);
  }
}

class GameSession extends DataClass implements Insertable<GameSession> {
  /// 对局唯一ID
  final int id;

  /// 词书ID
  final String bookId;

  /// 领域ID（领域游戏时使用）
  final String? domainId;

  /// 游戏模式 (word/domain)
  final String gameMode;

  /// 网格大小 (3x3/4x4/5x5)
  final int gridSize;

  /// 匹配成功数
  final int matchCount;

  /// 错误次数
  final int errorCount;

  /// 使用提示次数
  final int hintCount;

  /// 游戏时长（毫秒）
  final int durationMs;

  /// 连击最高记录
  final int maxCombo;

  /// 得分
  final int score;

  /// 是否完成
  final bool isCompleted;

  /// 开始时间
  final DateTime startTime;

  /// 结束时间
  final DateTime? endTime;

  /// 创建时间
  final DateTime createdAt;
  const GameSession(
      {required this.id,
      required this.bookId,
      this.domainId,
      required this.gameMode,
      required this.gridSize,
      required this.matchCount,
      required this.errorCount,
      required this.hintCount,
      required this.durationMs,
      required this.maxCombo,
      required this.score,
      required this.isCompleted,
      required this.startTime,
      this.endTime,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<String>(bookId);
    if (!nullToAbsent || domainId != null) {
      map['domain_id'] = Variable<String>(domainId);
    }
    map['game_mode'] = Variable<String>(gameMode);
    map['grid_size'] = Variable<int>(gridSize);
    map['match_count'] = Variable<int>(matchCount);
    map['error_count'] = Variable<int>(errorCount);
    map['hint_count'] = Variable<int>(hintCount);
    map['duration_ms'] = Variable<int>(durationMs);
    map['max_combo'] = Variable<int>(maxCombo);
    map['score'] = Variable<int>(score);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GameSessionsCompanion toCompanion(bool nullToAbsent) {
    return GameSessionsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      domainId: domainId == null && nullToAbsent
          ? const Value.absent()
          : Value(domainId),
      gameMode: Value(gameMode),
      gridSize: Value(gridSize),
      matchCount: Value(matchCount),
      errorCount: Value(errorCount),
      hintCount: Value(hintCount),
      durationMs: Value(durationMs),
      maxCombo: Value(maxCombo),
      score: Value(score),
      isCompleted: Value(isCompleted),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      createdAt: Value(createdAt),
    );
  }

  factory GameSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameSession(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      domainId: serializer.fromJson<String?>(json['domainId']),
      gameMode: serializer.fromJson<String>(json['gameMode']),
      gridSize: serializer.fromJson<int>(json['gridSize']),
      matchCount: serializer.fromJson<int>(json['matchCount']),
      errorCount: serializer.fromJson<int>(json['errorCount']),
      hintCount: serializer.fromJson<int>(json['hintCount']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      maxCombo: serializer.fromJson<int>(json['maxCombo']),
      score: serializer.fromJson<int>(json['score']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<String>(bookId),
      'domainId': serializer.toJson<String?>(domainId),
      'gameMode': serializer.toJson<String>(gameMode),
      'gridSize': serializer.toJson<int>(gridSize),
      'matchCount': serializer.toJson<int>(matchCount),
      'errorCount': serializer.toJson<int>(errorCount),
      'hintCount': serializer.toJson<int>(hintCount),
      'durationMs': serializer.toJson<int>(durationMs),
      'maxCombo': serializer.toJson<int>(maxCombo),
      'score': serializer.toJson<int>(score),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GameSession copyWith(
          {int? id,
          String? bookId,
          Value<String?> domainId = const Value.absent(),
          String? gameMode,
          int? gridSize,
          int? matchCount,
          int? errorCount,
          int? hintCount,
          int? durationMs,
          int? maxCombo,
          int? score,
          bool? isCompleted,
          DateTime? startTime,
          Value<DateTime?> endTime = const Value.absent(),
          DateTime? createdAt}) =>
      GameSession(
        id: id ?? this.id,
        bookId: bookId ?? this.bookId,
        domainId: domainId.present ? domainId.value : this.domainId,
        gameMode: gameMode ?? this.gameMode,
        gridSize: gridSize ?? this.gridSize,
        matchCount: matchCount ?? this.matchCount,
        errorCount: errorCount ?? this.errorCount,
        hintCount: hintCount ?? this.hintCount,
        durationMs: durationMs ?? this.durationMs,
        maxCombo: maxCombo ?? this.maxCombo,
        score: score ?? this.score,
        isCompleted: isCompleted ?? this.isCompleted,
        startTime: startTime ?? this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        createdAt: createdAt ?? this.createdAt,
      );
  GameSession copyWithCompanion(GameSessionsCompanion data) {
    return GameSession(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      domainId: data.domainId.present ? data.domainId.value : this.domainId,
      gameMode: data.gameMode.present ? data.gameMode.value : this.gameMode,
      gridSize: data.gridSize.present ? data.gridSize.value : this.gridSize,
      matchCount:
          data.matchCount.present ? data.matchCount.value : this.matchCount,
      errorCount:
          data.errorCount.present ? data.errorCount.value : this.errorCount,
      hintCount: data.hintCount.present ? data.hintCount.value : this.hintCount,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      maxCombo: data.maxCombo.present ? data.maxCombo.value : this.maxCombo,
      score: data.score.present ? data.score.value : this.score,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameSession(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('domainId: $domainId, ')
          ..write('gameMode: $gameMode, ')
          ..write('gridSize: $gridSize, ')
          ..write('matchCount: $matchCount, ')
          ..write('errorCount: $errorCount, ')
          ..write('hintCount: $hintCount, ')
          ..write('durationMs: $durationMs, ')
          ..write('maxCombo: $maxCombo, ')
          ..write('score: $score, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      bookId,
      domainId,
      gameMode,
      gridSize,
      matchCount,
      errorCount,
      hintCount,
      durationMs,
      maxCombo,
      score,
      isCompleted,
      startTime,
      endTime,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameSession &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.domainId == this.domainId &&
          other.gameMode == this.gameMode &&
          other.gridSize == this.gridSize &&
          other.matchCount == this.matchCount &&
          other.errorCount == this.errorCount &&
          other.hintCount == this.hintCount &&
          other.durationMs == this.durationMs &&
          other.maxCombo == this.maxCombo &&
          other.score == this.score &&
          other.isCompleted == this.isCompleted &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.createdAt == this.createdAt);
}

class GameSessionsCompanion extends UpdateCompanion<GameSession> {
  final Value<int> id;
  final Value<String> bookId;
  final Value<String?> domainId;
  final Value<String> gameMode;
  final Value<int> gridSize;
  final Value<int> matchCount;
  final Value<int> errorCount;
  final Value<int> hintCount;
  final Value<int> durationMs;
  final Value<int> maxCombo;
  final Value<int> score;
  final Value<bool> isCompleted;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<DateTime> createdAt;
  const GameSessionsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.domainId = const Value.absent(),
    this.gameMode = const Value.absent(),
    this.gridSize = const Value.absent(),
    this.matchCount = const Value.absent(),
    this.errorCount = const Value.absent(),
    this.hintCount = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.maxCombo = const Value.absent(),
    this.score = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GameSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String bookId,
    this.domainId = const Value.absent(),
    this.gameMode = const Value.absent(),
    required int gridSize,
    this.matchCount = const Value.absent(),
    this.errorCount = const Value.absent(),
    this.hintCount = const Value.absent(),
    required int durationMs,
    this.maxCombo = const Value.absent(),
    this.score = const Value.absent(),
    this.isCompleted = const Value.absent(),
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : bookId = Value(bookId),
        gridSize = Value(gridSize),
        durationMs = Value(durationMs),
        startTime = Value(startTime);
  static Insertable<GameSession> custom({
    Expression<int>? id,
    Expression<String>? bookId,
    Expression<String>? domainId,
    Expression<String>? gameMode,
    Expression<int>? gridSize,
    Expression<int>? matchCount,
    Expression<int>? errorCount,
    Expression<int>? hintCount,
    Expression<int>? durationMs,
    Expression<int>? maxCombo,
    Expression<int>? score,
    Expression<bool>? isCompleted,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (domainId != null) 'domain_id': domainId,
      if (gameMode != null) 'game_mode': gameMode,
      if (gridSize != null) 'grid_size': gridSize,
      if (matchCount != null) 'match_count': matchCount,
      if (errorCount != null) 'error_count': errorCount,
      if (hintCount != null) 'hint_count': hintCount,
      if (durationMs != null) 'duration_ms': durationMs,
      if (maxCombo != null) 'max_combo': maxCombo,
      if (score != null) 'score': score,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GameSessionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? bookId,
      Value<String?>? domainId,
      Value<String>? gameMode,
      Value<int>? gridSize,
      Value<int>? matchCount,
      Value<int>? errorCount,
      Value<int>? hintCount,
      Value<int>? durationMs,
      Value<int>? maxCombo,
      Value<int>? score,
      Value<bool>? isCompleted,
      Value<DateTime>? startTime,
      Value<DateTime?>? endTime,
      Value<DateTime>? createdAt}) {
    return GameSessionsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      domainId: domainId ?? this.domainId,
      gameMode: gameMode ?? this.gameMode,
      gridSize: gridSize ?? this.gridSize,
      matchCount: matchCount ?? this.matchCount,
      errorCount: errorCount ?? this.errorCount,
      hintCount: hintCount ?? this.hintCount,
      durationMs: durationMs ?? this.durationMs,
      maxCombo: maxCombo ?? this.maxCombo,
      score: score ?? this.score,
      isCompleted: isCompleted ?? this.isCompleted,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (domainId.present) {
      map['domain_id'] = Variable<String>(domainId.value);
    }
    if (gameMode.present) {
      map['game_mode'] = Variable<String>(gameMode.value);
    }
    if (gridSize.present) {
      map['grid_size'] = Variable<int>(gridSize.value);
    }
    if (matchCount.present) {
      map['match_count'] = Variable<int>(matchCount.value);
    }
    if (errorCount.present) {
      map['error_count'] = Variable<int>(errorCount.value);
    }
    if (hintCount.present) {
      map['hint_count'] = Variable<int>(hintCount.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (maxCombo.present) {
      map['max_combo'] = Variable<int>(maxCombo.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameSessionsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('domainId: $domainId, ')
          ..write('gameMode: $gameMode, ')
          ..write('gridSize: $gridSize, ')
          ..write('matchCount: $matchCount, ')
          ..write('errorCount: $errorCount, ')
          ..write('hintCount: $hintCount, ')
          ..write('durationMs: $durationMs, ')
          ..write('maxCombo: $maxCombo, ')
          ..write('score: $score, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LearningPlansTable extends LearningPlans
    with TableInfo<$LearningPlansTable, LearningPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _examDateMeta =
      const VerificationMeta('examDate');
  @override
  late final GeneratedColumn<DateTime> examDate = GeneratedColumn<DateTime>(
      'exam_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _dailyMinutesMeta =
      const VerificationMeta('dailyMinutes');
  @override
  late final GeneratedColumn<int> dailyMinutes = GeneratedColumn<int>(
      'daily_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dailyNewWordsMeta =
      const VerificationMeta('dailyNewWords');
  @override
  late final GeneratedColumn<int> dailyNewWords = GeneratedColumn<int>(
      'daily_new_words', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(20));
  static const VerificationMeta _learnedDaysMeta =
      const VerificationMeta('learnedDays');
  @override
  late final GeneratedColumn<int> learnedDays = GeneratedColumn<int>(
      'learned_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        bookId,
        examDate,
        dailyMinutes,
        dailyNewWords,
        learnedDays,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_plans';
  @override
  VerificationContext validateIntegrity(Insertable<LearningPlan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('exam_date')) {
      context.handle(_examDateMeta,
          examDate.isAcceptableOrUnknown(data['exam_date']!, _examDateMeta));
    } else if (isInserting) {
      context.missing(_examDateMeta);
    }
    if (data.containsKey('daily_minutes')) {
      context.handle(
          _dailyMinutesMeta,
          dailyMinutes.isAcceptableOrUnknown(
              data['daily_minutes']!, _dailyMinutesMeta));
    } else if (isInserting) {
      context.missing(_dailyMinutesMeta);
    }
    if (data.containsKey('daily_new_words')) {
      context.handle(
          _dailyNewWordsMeta,
          dailyNewWords.isAcceptableOrUnknown(
              data['daily_new_words']!, _dailyNewWordsMeta));
    }
    if (data.containsKey('learned_days')) {
      context.handle(
          _learnedDaysMeta,
          learnedDays.isAcceptableOrUnknown(
              data['learned_days']!, _learnedDaysMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningPlan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      examDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}exam_date'])!,
      dailyMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}daily_minutes'])!,
      dailyNewWords: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}daily_new_words'])!,
      learnedDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}learned_days'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LearningPlansTable createAlias(String alias) {
    return $LearningPlansTable(attachedDatabase, alias);
  }
}

class LearningPlan extends DataClass implements Insertable<LearningPlan> {
  /// 计划唯一ID
  final int id;

  /// 词书ID
  final String bookId;

  /// 考试/目标日期
  final DateTime examDate;

  /// 每日学习时长（分钟）
  final int dailyMinutes;

  /// 每日新词目标
  final int dailyNewWords;

  /// 已学习天数
  final int learnedDays;

  /// 是否激活
  final bool isActive;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;
  const LearningPlan(
      {required this.id,
      required this.bookId,
      required this.examDate,
      required this.dailyMinutes,
      required this.dailyNewWords,
      required this.learnedDays,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<String>(bookId);
    map['exam_date'] = Variable<DateTime>(examDate);
    map['daily_minutes'] = Variable<int>(dailyMinutes);
    map['daily_new_words'] = Variable<int>(dailyNewWords);
    map['learned_days'] = Variable<int>(learnedDays);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LearningPlansCompanion toCompanion(bool nullToAbsent) {
    return LearningPlansCompanion(
      id: Value(id),
      bookId: Value(bookId),
      examDate: Value(examDate),
      dailyMinutes: Value(dailyMinutes),
      dailyNewWords: Value(dailyNewWords),
      learnedDays: Value(learnedDays),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LearningPlan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningPlan(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      examDate: serializer.fromJson<DateTime>(json['examDate']),
      dailyMinutes: serializer.fromJson<int>(json['dailyMinutes']),
      dailyNewWords: serializer.fromJson<int>(json['dailyNewWords']),
      learnedDays: serializer.fromJson<int>(json['learnedDays']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<String>(bookId),
      'examDate': serializer.toJson<DateTime>(examDate),
      'dailyMinutes': serializer.toJson<int>(dailyMinutes),
      'dailyNewWords': serializer.toJson<int>(dailyNewWords),
      'learnedDays': serializer.toJson<int>(learnedDays),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LearningPlan copyWith(
          {int? id,
          String? bookId,
          DateTime? examDate,
          int? dailyMinutes,
          int? dailyNewWords,
          int? learnedDays,
          bool? isActive,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      LearningPlan(
        id: id ?? this.id,
        bookId: bookId ?? this.bookId,
        examDate: examDate ?? this.examDate,
        dailyMinutes: dailyMinutes ?? this.dailyMinutes,
        dailyNewWords: dailyNewWords ?? this.dailyNewWords,
        learnedDays: learnedDays ?? this.learnedDays,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LearningPlan copyWithCompanion(LearningPlansCompanion data) {
    return LearningPlan(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      examDate: data.examDate.present ? data.examDate.value : this.examDate,
      dailyMinutes: data.dailyMinutes.present
          ? data.dailyMinutes.value
          : this.dailyMinutes,
      dailyNewWords: data.dailyNewWords.present
          ? data.dailyNewWords.value
          : this.dailyNewWords,
      learnedDays:
          data.learnedDays.present ? data.learnedDays.value : this.learnedDays,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningPlan(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('examDate: $examDate, ')
          ..write('dailyMinutes: $dailyMinutes, ')
          ..write('dailyNewWords: $dailyNewWords, ')
          ..write('learnedDays: $learnedDays, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bookId, examDate, dailyMinutes,
      dailyNewWords, learnedDays, isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningPlan &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.examDate == this.examDate &&
          other.dailyMinutes == this.dailyMinutes &&
          other.dailyNewWords == this.dailyNewWords &&
          other.learnedDays == this.learnedDays &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LearningPlansCompanion extends UpdateCompanion<LearningPlan> {
  final Value<int> id;
  final Value<String> bookId;
  final Value<DateTime> examDate;
  final Value<int> dailyMinutes;
  final Value<int> dailyNewWords;
  final Value<int> learnedDays;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const LearningPlansCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.examDate = const Value.absent(),
    this.dailyMinutes = const Value.absent(),
    this.dailyNewWords = const Value.absent(),
    this.learnedDays = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LearningPlansCompanion.insert({
    this.id = const Value.absent(),
    required String bookId,
    required DateTime examDate,
    required int dailyMinutes,
    this.dailyNewWords = const Value.absent(),
    this.learnedDays = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : bookId = Value(bookId),
        examDate = Value(examDate),
        dailyMinutes = Value(dailyMinutes);
  static Insertable<LearningPlan> custom({
    Expression<int>? id,
    Expression<String>? bookId,
    Expression<DateTime>? examDate,
    Expression<int>? dailyMinutes,
    Expression<int>? dailyNewWords,
    Expression<int>? learnedDays,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (examDate != null) 'exam_date': examDate,
      if (dailyMinutes != null) 'daily_minutes': dailyMinutes,
      if (dailyNewWords != null) 'daily_new_words': dailyNewWords,
      if (learnedDays != null) 'learned_days': learnedDays,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LearningPlansCompanion copyWith(
      {Value<int>? id,
      Value<String>? bookId,
      Value<DateTime>? examDate,
      Value<int>? dailyMinutes,
      Value<int>? dailyNewWords,
      Value<int>? learnedDays,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return LearningPlansCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      examDate: examDate ?? this.examDate,
      dailyMinutes: dailyMinutes ?? this.dailyMinutes,
      dailyNewWords: dailyNewWords ?? this.dailyNewWords,
      learnedDays: learnedDays ?? this.learnedDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (examDate.present) {
      map['exam_date'] = Variable<DateTime>(examDate.value);
    }
    if (dailyMinutes.present) {
      map['daily_minutes'] = Variable<int>(dailyMinutes.value);
    }
    if (dailyNewWords.present) {
      map['daily_new_words'] = Variable<int>(dailyNewWords.value);
    }
    if (learnedDays.present) {
      map['learned_days'] = Variable<int>(learnedDays.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningPlansCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('examDate: $examDate, ')
          ..write('dailyMinutes: $dailyMinutes, ')
          ..write('dailyNewWords: $dailyNewWords, ')
          ..write('learnedDays: $learnedDays, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WordsTable words = $WordsTable(this);
  late final $UserWordProgressTable userWordProgress =
      $UserWordProgressTable(this);
  late final $GameSessionsTable gameSessions = $GameSessionsTable(this);
  late final $LearningPlansTable learningPlans = $LearningPlansTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [words, userWordProgress, gameSessions, learningPlans];
}

typedef $$WordsTableCreateCompanionBuilder = WordsCompanion Function({
  required String id,
  required String word,
  Value<String?> phoneticUs,
  Value<String?> phoneticUk,
  required String definition,
  Value<String?> exampleSentence,
  Value<int> frequency,
  required String bookId,
  Value<String?> rootParts,
  Value<bool> hasMnemonic,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$WordsTableUpdateCompanionBuilder = WordsCompanion Function({
  Value<String> id,
  Value<String> word,
  Value<String?> phoneticUs,
  Value<String?> phoneticUk,
  Value<String> definition,
  Value<String?> exampleSentence,
  Value<int> frequency,
  Value<String> bookId,
  Value<String?> rootParts,
  Value<bool> hasMnemonic,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get word => $composableBuilder(
      column: $table.word, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneticUs => $composableBuilder(
      column: $table.phoneticUs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneticUk => $composableBuilder(
      column: $table.phoneticUk, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get definition => $composableBuilder(
      column: $table.definition, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exampleSentence => $composableBuilder(
      column: $table.exampleSentence,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rootParts => $composableBuilder(
      column: $table.rootParts, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasMnemonic => $composableBuilder(
      column: $table.hasMnemonic, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get word => $composableBuilder(
      column: $table.word, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneticUs => $composableBuilder(
      column: $table.phoneticUs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneticUk => $composableBuilder(
      column: $table.phoneticUk, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get definition => $composableBuilder(
      column: $table.definition, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exampleSentence => $composableBuilder(
      column: $table.exampleSentence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rootParts => $composableBuilder(
      column: $table.rootParts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasMnemonic => $composableBuilder(
      column: $table.hasMnemonic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get phoneticUs => $composableBuilder(
      column: $table.phoneticUs, builder: (column) => column);

  GeneratedColumn<String> get phoneticUk => $composableBuilder(
      column: $table.phoneticUk, builder: (column) => column);

  GeneratedColumn<String> get definition => $composableBuilder(
      column: $table.definition, builder: (column) => column);

  GeneratedColumn<String> get exampleSentence => $composableBuilder(
      column: $table.exampleSentence, builder: (column) => column);

  GeneratedColumn<int> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get rootParts =>
      $composableBuilder(column: $table.rootParts, builder: (column) => column);

  GeneratedColumn<bool> get hasMnemonic => $composableBuilder(
      column: $table.hasMnemonic, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$WordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WordsTable,
    Word,
    $$WordsTableFilterComposer,
    $$WordsTableOrderingComposer,
    $$WordsTableAnnotationComposer,
    $$WordsTableCreateCompanionBuilder,
    $$WordsTableUpdateCompanionBuilder,
    (Word, BaseReferences<_$AppDatabase, $WordsTable, Word>),
    Word,
    PrefetchHooks Function()> {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> word = const Value.absent(),
            Value<String?> phoneticUs = const Value.absent(),
            Value<String?> phoneticUk = const Value.absent(),
            Value<String> definition = const Value.absent(),
            Value<String?> exampleSentence = const Value.absent(),
            Value<int> frequency = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<String?> rootParts = const Value.absent(),
            Value<bool> hasMnemonic = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WordsCompanion(
            id: id,
            word: word,
            phoneticUs: phoneticUs,
            phoneticUk: phoneticUk,
            definition: definition,
            exampleSentence: exampleSentence,
            frequency: frequency,
            bookId: bookId,
            rootParts: rootParts,
            hasMnemonic: hasMnemonic,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String word,
            Value<String?> phoneticUs = const Value.absent(),
            Value<String?> phoneticUk = const Value.absent(),
            required String definition,
            Value<String?> exampleSentence = const Value.absent(),
            Value<int> frequency = const Value.absent(),
            required String bookId,
            Value<String?> rootParts = const Value.absent(),
            Value<bool> hasMnemonic = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WordsCompanion.insert(
            id: id,
            word: word,
            phoneticUs: phoneticUs,
            phoneticUk: phoneticUk,
            definition: definition,
            exampleSentence: exampleSentence,
            frequency: frequency,
            bookId: bookId,
            rootParts: rootParts,
            hasMnemonic: hasMnemonic,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WordsTable,
    Word,
    $$WordsTableFilterComposer,
    $$WordsTableOrderingComposer,
    $$WordsTableAnnotationComposer,
    $$WordsTableCreateCompanionBuilder,
    $$WordsTableUpdateCompanionBuilder,
    (Word, BaseReferences<_$AppDatabase, $WordsTable, Word>),
    Word,
    PrefetchHooks Function()>;
typedef $$UserWordProgressTableCreateCompanionBuilder
    = UserWordProgressCompanion Function({
  required String wordId,
  required String bookId,
  Value<double> easinessFactor,
  Value<int> intervalDays,
  Value<int> repetitions,
  required DateTime nextReviewDate,
  Value<int> lastQuality,
  Value<bool> isMastered,
  Value<int> reviewDebt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$UserWordProgressTableUpdateCompanionBuilder
    = UserWordProgressCompanion Function({
  Value<String> wordId,
  Value<String> bookId,
  Value<double> easinessFactor,
  Value<int> intervalDays,
  Value<int> repetitions,
  Value<DateTime> nextReviewDate,
  Value<int> lastQuality,
  Value<bool> isMastered,
  Value<int> reviewDebt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$UserWordProgressTableFilterComposer
    extends Composer<_$AppDatabase, $UserWordProgressTable> {
  $$UserWordProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get easinessFactor => $composableBuilder(
      column: $table.easinessFactor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get repetitions => $composableBuilder(
      column: $table.repetitions, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextReviewDate => $composableBuilder(
      column: $table.nextReviewDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastQuality => $composableBuilder(
      column: $table.lastQuality, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isMastered => $composableBuilder(
      column: $table.isMastered, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reviewDebt => $composableBuilder(
      column: $table.reviewDebt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$UserWordProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $UserWordProgressTable> {
  $$UserWordProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get easinessFactor => $composableBuilder(
      column: $table.easinessFactor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get repetitions => $composableBuilder(
      column: $table.repetitions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextReviewDate => $composableBuilder(
      column: $table.nextReviewDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastQuality => $composableBuilder(
      column: $table.lastQuality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isMastered => $composableBuilder(
      column: $table.isMastered, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reviewDebt => $composableBuilder(
      column: $table.reviewDebt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$UserWordProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserWordProgressTable> {
  $$UserWordProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<double> get easinessFactor => $composableBuilder(
      column: $table.easinessFactor, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays, builder: (column) => column);

  GeneratedColumn<int> get repetitions => $composableBuilder(
      column: $table.repetitions, builder: (column) => column);

  GeneratedColumn<DateTime> get nextReviewDate => $composableBuilder(
      column: $table.nextReviewDate, builder: (column) => column);

  GeneratedColumn<int> get lastQuality => $composableBuilder(
      column: $table.lastQuality, builder: (column) => column);

  GeneratedColumn<bool> get isMastered => $composableBuilder(
      column: $table.isMastered, builder: (column) => column);

  GeneratedColumn<int> get reviewDebt => $composableBuilder(
      column: $table.reviewDebt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserWordProgressTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserWordProgressTable,
    UserWordProgressData,
    $$UserWordProgressTableFilterComposer,
    $$UserWordProgressTableOrderingComposer,
    $$UserWordProgressTableAnnotationComposer,
    $$UserWordProgressTableCreateCompanionBuilder,
    $$UserWordProgressTableUpdateCompanionBuilder,
    (
      UserWordProgressData,
      BaseReferences<_$AppDatabase, $UserWordProgressTable,
          UserWordProgressData>
    ),
    UserWordProgressData,
    PrefetchHooks Function()> {
  $$UserWordProgressTableTableManager(
      _$AppDatabase db, $UserWordProgressTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserWordProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserWordProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserWordProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> wordId = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<double> easinessFactor = const Value.absent(),
            Value<int> intervalDays = const Value.absent(),
            Value<int> repetitions = const Value.absent(),
            Value<DateTime> nextReviewDate = const Value.absent(),
            Value<int> lastQuality = const Value.absent(),
            Value<bool> isMastered = const Value.absent(),
            Value<int> reviewDebt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserWordProgressCompanion(
            wordId: wordId,
            bookId: bookId,
            easinessFactor: easinessFactor,
            intervalDays: intervalDays,
            repetitions: repetitions,
            nextReviewDate: nextReviewDate,
            lastQuality: lastQuality,
            isMastered: isMastered,
            reviewDebt: reviewDebt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String wordId,
            required String bookId,
            Value<double> easinessFactor = const Value.absent(),
            Value<int> intervalDays = const Value.absent(),
            Value<int> repetitions = const Value.absent(),
            required DateTime nextReviewDate,
            Value<int> lastQuality = const Value.absent(),
            Value<bool> isMastered = const Value.absent(),
            Value<int> reviewDebt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserWordProgressCompanion.insert(
            wordId: wordId,
            bookId: bookId,
            easinessFactor: easinessFactor,
            intervalDays: intervalDays,
            repetitions: repetitions,
            nextReviewDate: nextReviewDate,
            lastQuality: lastQuality,
            isMastered: isMastered,
            reviewDebt: reviewDebt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserWordProgressTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserWordProgressTable,
    UserWordProgressData,
    $$UserWordProgressTableFilterComposer,
    $$UserWordProgressTableOrderingComposer,
    $$UserWordProgressTableAnnotationComposer,
    $$UserWordProgressTableCreateCompanionBuilder,
    $$UserWordProgressTableUpdateCompanionBuilder,
    (
      UserWordProgressData,
      BaseReferences<_$AppDatabase, $UserWordProgressTable,
          UserWordProgressData>
    ),
    UserWordProgressData,
    PrefetchHooks Function()>;
typedef $$GameSessionsTableCreateCompanionBuilder = GameSessionsCompanion
    Function({
  Value<int> id,
  required String bookId,
  Value<String?> domainId,
  Value<String> gameMode,
  required int gridSize,
  Value<int> matchCount,
  Value<int> errorCount,
  Value<int> hintCount,
  required int durationMs,
  Value<int> maxCombo,
  Value<int> score,
  Value<bool> isCompleted,
  required DateTime startTime,
  Value<DateTime?> endTime,
  Value<DateTime> createdAt,
});
typedef $$GameSessionsTableUpdateCompanionBuilder = GameSessionsCompanion
    Function({
  Value<int> id,
  Value<String> bookId,
  Value<String?> domainId,
  Value<String> gameMode,
  Value<int> gridSize,
  Value<int> matchCount,
  Value<int> errorCount,
  Value<int> hintCount,
  Value<int> durationMs,
  Value<int> maxCombo,
  Value<int> score,
  Value<bool> isCompleted,
  Value<DateTime> startTime,
  Value<DateTime?> endTime,
  Value<DateTime> createdAt,
});

class $$GameSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $GameSessionsTable> {
  $$GameSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get domainId => $composableBuilder(
      column: $table.domainId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gameMode => $composableBuilder(
      column: $table.gameMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gridSize => $composableBuilder(
      column: $table.gridSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get matchCount => $composableBuilder(
      column: $table.matchCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get errorCount => $composableBuilder(
      column: $table.errorCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hintCount => $composableBuilder(
      column: $table.hintCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxCombo => $composableBuilder(
      column: $table.maxCombo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$GameSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $GameSessionsTable> {
  $$GameSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get domainId => $composableBuilder(
      column: $table.domainId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gameMode => $composableBuilder(
      column: $table.gameMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gridSize => $composableBuilder(
      column: $table.gridSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get matchCount => $composableBuilder(
      column: $table.matchCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get errorCount => $composableBuilder(
      column: $table.errorCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hintCount => $composableBuilder(
      column: $table.hintCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxCombo => $composableBuilder(
      column: $table.maxCombo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$GameSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameSessionsTable> {
  $$GameSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get domainId =>
      $composableBuilder(column: $table.domainId, builder: (column) => column);

  GeneratedColumn<String> get gameMode =>
      $composableBuilder(column: $table.gameMode, builder: (column) => column);

  GeneratedColumn<int> get gridSize =>
      $composableBuilder(column: $table.gridSize, builder: (column) => column);

  GeneratedColumn<int> get matchCount => $composableBuilder(
      column: $table.matchCount, builder: (column) => column);

  GeneratedColumn<int> get errorCount => $composableBuilder(
      column: $table.errorCount, builder: (column) => column);

  GeneratedColumn<int> get hintCount =>
      $composableBuilder(column: $table.hintCount, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<int> get maxCombo =>
      $composableBuilder(column: $table.maxCombo, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GameSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GameSessionsTable,
    GameSession,
    $$GameSessionsTableFilterComposer,
    $$GameSessionsTableOrderingComposer,
    $$GameSessionsTableAnnotationComposer,
    $$GameSessionsTableCreateCompanionBuilder,
    $$GameSessionsTableUpdateCompanionBuilder,
    (
      GameSession,
      BaseReferences<_$AppDatabase, $GameSessionsTable, GameSession>
    ),
    GameSession,
    PrefetchHooks Function()> {
  $$GameSessionsTableTableManager(_$AppDatabase db, $GameSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<String?> domainId = const Value.absent(),
            Value<String> gameMode = const Value.absent(),
            Value<int> gridSize = const Value.absent(),
            Value<int> matchCount = const Value.absent(),
            Value<int> errorCount = const Value.absent(),
            Value<int> hintCount = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<int> maxCombo = const Value.absent(),
            Value<int> score = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              GameSessionsCompanion(
            id: id,
            bookId: bookId,
            domainId: domainId,
            gameMode: gameMode,
            gridSize: gridSize,
            matchCount: matchCount,
            errorCount: errorCount,
            hintCount: hintCount,
            durationMs: durationMs,
            maxCombo: maxCombo,
            score: score,
            isCompleted: isCompleted,
            startTime: startTime,
            endTime: endTime,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String bookId,
            Value<String?> domainId = const Value.absent(),
            Value<String> gameMode = const Value.absent(),
            required int gridSize,
            Value<int> matchCount = const Value.absent(),
            Value<int> errorCount = const Value.absent(),
            Value<int> hintCount = const Value.absent(),
            required int durationMs,
            Value<int> maxCombo = const Value.absent(),
            Value<int> score = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            required DateTime startTime,
            Value<DateTime?> endTime = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              GameSessionsCompanion.insert(
            id: id,
            bookId: bookId,
            domainId: domainId,
            gameMode: gameMode,
            gridSize: gridSize,
            matchCount: matchCount,
            errorCount: errorCount,
            hintCount: hintCount,
            durationMs: durationMs,
            maxCombo: maxCombo,
            score: score,
            isCompleted: isCompleted,
            startTime: startTime,
            endTime: endTime,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GameSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GameSessionsTable,
    GameSession,
    $$GameSessionsTableFilterComposer,
    $$GameSessionsTableOrderingComposer,
    $$GameSessionsTableAnnotationComposer,
    $$GameSessionsTableCreateCompanionBuilder,
    $$GameSessionsTableUpdateCompanionBuilder,
    (
      GameSession,
      BaseReferences<_$AppDatabase, $GameSessionsTable, GameSession>
    ),
    GameSession,
    PrefetchHooks Function()>;
typedef $$LearningPlansTableCreateCompanionBuilder = LearningPlansCompanion
    Function({
  Value<int> id,
  required String bookId,
  required DateTime examDate,
  required int dailyMinutes,
  Value<int> dailyNewWords,
  Value<int> learnedDays,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$LearningPlansTableUpdateCompanionBuilder = LearningPlansCompanion
    Function({
  Value<int> id,
  Value<String> bookId,
  Value<DateTime> examDate,
  Value<int> dailyMinutes,
  Value<int> dailyNewWords,
  Value<int> learnedDays,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$LearningPlansTableFilterComposer
    extends Composer<_$AppDatabase, $LearningPlansTable> {
  $$LearningPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get examDate => $composableBuilder(
      column: $table.examDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dailyMinutes => $composableBuilder(
      column: $table.dailyMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dailyNewWords => $composableBuilder(
      column: $table.dailyNewWords, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get learnedDays => $composableBuilder(
      column: $table.learnedDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LearningPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningPlansTable> {
  $$LearningPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get examDate => $composableBuilder(
      column: $table.examDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dailyMinutes => $composableBuilder(
      column: $table.dailyMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dailyNewWords => $composableBuilder(
      column: $table.dailyNewWords,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get learnedDays => $composableBuilder(
      column: $table.learnedDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LearningPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningPlansTable> {
  $$LearningPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<DateTime> get examDate =>
      $composableBuilder(column: $table.examDate, builder: (column) => column);

  GeneratedColumn<int> get dailyMinutes => $composableBuilder(
      column: $table.dailyMinutes, builder: (column) => column);

  GeneratedColumn<int> get dailyNewWords => $composableBuilder(
      column: $table.dailyNewWords, builder: (column) => column);

  GeneratedColumn<int> get learnedDays => $composableBuilder(
      column: $table.learnedDays, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LearningPlansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LearningPlansTable,
    LearningPlan,
    $$LearningPlansTableFilterComposer,
    $$LearningPlansTableOrderingComposer,
    $$LearningPlansTableAnnotationComposer,
    $$LearningPlansTableCreateCompanionBuilder,
    $$LearningPlansTableUpdateCompanionBuilder,
    (
      LearningPlan,
      BaseReferences<_$AppDatabase, $LearningPlansTable, LearningPlan>
    ),
    LearningPlan,
    PrefetchHooks Function()> {
  $$LearningPlansTableTableManager(_$AppDatabase db, $LearningPlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<DateTime> examDate = const Value.absent(),
            Value<int> dailyMinutes = const Value.absent(),
            Value<int> dailyNewWords = const Value.absent(),
            Value<int> learnedDays = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              LearningPlansCompanion(
            id: id,
            bookId: bookId,
            examDate: examDate,
            dailyMinutes: dailyMinutes,
            dailyNewWords: dailyNewWords,
            learnedDays: learnedDays,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String bookId,
            required DateTime examDate,
            required int dailyMinutes,
            Value<int> dailyNewWords = const Value.absent(),
            Value<int> learnedDays = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              LearningPlansCompanion.insert(
            id: id,
            bookId: bookId,
            examDate: examDate,
            dailyMinutes: dailyMinutes,
            dailyNewWords: dailyNewWords,
            learnedDays: learnedDays,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LearningPlansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LearningPlansTable,
    LearningPlan,
    $$LearningPlansTableFilterComposer,
    $$LearningPlansTableOrderingComposer,
    $$LearningPlansTableAnnotationComposer,
    $$LearningPlansTableCreateCompanionBuilder,
    $$LearningPlansTableUpdateCompanionBuilder,
    (
      LearningPlan,
      BaseReferences<_$AppDatabase, $LearningPlansTable, LearningPlan>
    ),
    LearningPlan,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$UserWordProgressTableTableManager get userWordProgress =>
      $$UserWordProgressTableTableManager(_db, _db.userWordProgress);
  $$GameSessionsTableTableManager get gameSessions =>
      $$GameSessionsTableTableManager(_db, _db.gameSessions);
  $$LearningPlansTableTableManager get learningPlans =>
      $$LearningPlansTableTableManager(_db, _db.learningPlans);
}
