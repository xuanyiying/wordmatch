import 'package:flutter/material.dart';

/// 卡牌类型：typeA（如英文、上句、元素符号）or typeB（如中文、下句、元素名称）
enum CardType { typeA, typeB }

/// 卡牌状态
enum CardState { revealed, selected, matched, shaking }

/// 游戏中的单张卡牌
class GameCard {
  final String itemId; // 配对项 ID（同一对 typeA/typeB 共享）
  final CardType type;
  final String text; // typeA 文本 or typeB 文本
  final String? phonetic; // 仅部分领域有音标（如英文单词）
  final Map<String, dynamic>? extra; // 领域专属附加数据

  final CardState state;
  final Offset position;
  final int gridIndex;

  const GameCard({
    required this.itemId,
    required this.type,
    required this.text,
    this.phonetic,
    this.extra,
    this.state = CardState.revealed,
    this.position = Offset.zero,
    this.gridIndex = -1,
  });

  /// 是否已被消除
  bool get isMatched => state == CardState.matched;

  /// 是否正在显示
  bool get isRevealed => state == CardState.revealed;

  /// 创建 typeA 卡牌
  factory GameCard.typeA({
    required String itemId,
    required String text,
    String? phonetic,
    Map<String, dynamic>? extra,
  }) =>
      GameCard(
        itemId: itemId,
        type: CardType.typeA,
        text: text,
        phonetic: phonetic,
        extra: extra,
      );

  /// 创建 typeB 卡牌
  factory GameCard.typeB({
    required String itemId,
    required String text,
    Map<String, dynamic>? extra,
  }) =>
      GameCard(
        itemId: itemId,
        type: CardType.typeB,
        text: text,
        extra: extra,
      );

  /// 兼容旧 JSON 的 fromJson（wordId → itemId）
  factory GameCard.fromJson(Map<String, dynamic> json) => GameCard(
        itemId: (json['itemId'] ?? json['wordId']) as String,
        type: json['type'] == 'typeA' || json['type'] == 'english'
            ? CardType.typeA
            : CardType.typeB,
        text: json['text'] as String,
        phonetic: json['phonetic'] as String?,
        extra: json['extra'] as Map<String, dynamic>?,
        state: CardState.revealed,
        position: Offset.zero,
        gridIndex: json['gridIndex'] as int? ?? -1,
      );

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'type': type == CardType.typeA ? 'typeA' : 'typeB',
        'text': text,
        if (phonetic != null) 'phonetic': phonetic,
        if (extra != null) 'extra': extra,
        'gridIndex': gridIndex,
      };

  GameCard copyWith({
    String? itemId,
    CardType? type,
    String? text,
    String? phonetic,
    Map<String, dynamic>? extra,
    CardState? state,
    Offset? position,
    int? gridIndex,
  }) =>
      GameCard(
        itemId: itemId ?? this.itemId,
        type: type ?? this.type,
        text: text ?? this.text,
        phonetic: phonetic ?? this.phonetic,
        extra: extra ?? this.extra,
        state: state ?? this.state,
        position: position ?? this.position,
        gridIndex: gridIndex ?? this.gridIndex,
      );
}
