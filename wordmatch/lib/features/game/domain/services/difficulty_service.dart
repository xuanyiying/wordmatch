import 'package:wordmatch/features/game/data/models/game_card.dart';
import 'package:wordmatch/features/game/data/models/game_state.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';

/// 防死局与动态难度服务
class DifficultyService {
  DifficultyService._();

  /// 校验当前网格是否存在至少一条可消除路径
  ///
  /// 检查是否存在至少一对 typeA+typeB 且 itemId 相同的卡牌
  static bool hasValidPath(List<GameCard> cards) {
    final typeACards =
        cards.where((c) => c.type == CardType.typeA && !c.isMatched).toList();
    final typeBCards =
        cards.where((c) => c.type == CardType.typeB && !c.isMatched).toList();

    for (final a in typeACards) {
      for (final b in typeBCards) {
        if (a.itemId == b.itemId) {
          return true;
        }
      }
    }
    return false;
  }

  /// 找到一对可消除的卡牌（用于 Hint 提示）
  ///
  /// 返回 [typeAIndex, typeBIndex]，如果没有可消除对则返回 null
  static List<int>? findHintPair(List<GameCard> cards) {
    for (var i = 0; i < cards.length; i++) {
      if (cards[i].type != CardType.typeA || cards[i].isMatched) continue;
      for (var j = 0; j < cards.length; j++) {
        if (cards[j].type != CardType.typeB || cards[j].isMatched) continue;
        if (cards[i].itemId == cards[j].itemId) {
          return [i, j];
        }
      }
    }
    return null;
  }

  /// 生成关卡卡牌（带防死局保障）
  ///
  /// 从词库中选择单词生成配对卡牌，并随机排列
  static List<GameCard> generateCards(List<Word> words, GridSize gridSize) {
    final pairs = gridSize == GridSize.small ? 8 : 18;
    final selectedWords = List<Word>.from(words);
    selectedWords.shuffle();
    final takenWords = selectedWords.take(pairs).toList();

    final cards = <GameCard>[];
    for (final w in takenWords) {
      cards.add(
          GameCard.typeA(itemId: w.id, text: w.word, phonetic: w.phoneticUs));
      cards.add(GameCard.typeB(itemId: w.id, text: w.definition.first));
    }

    // 随机排列
    cards.shuffle();

    // 设置网格索引
    for (var i = 0; i < cards.length; i++) {
      cards[i] = cards[i].copyWith(gridIndex: i);
    }

    // 防死局校验（理论上不会出现，因为配对是完整生成的）
    assert(hasValidPath(cards), '关卡生成错误：不存在可消除路径');

    return cards;
  }

  /// 根据正确率决定是否需要增加干扰项
  ///
  /// 正确率 > 90% 时，替换部分 typeB 文本为同局其他词的释义
  /// 这使得玩家需要更仔细辨别，因为看到的释义可能不是正确的配对
  /// 返回增加干扰项后的卡牌列表
  static List<GameCard> addDistractors(
    List<GameCard> cards,
    List<Word> allWords,
    double accuracy,
  ) {
    if (accuracy <= 0.9) return cards;

    // 干扰强度：正确率越高，替换越多释义
    final distractorCount = accuracy > 0.95 ? 3 : 2;

    final typeBIndices = <int>[];
    for (var i = 0; i < cards.length; i++) {
      if (cards[i].type == CardType.typeB) {
        typeBIndices.add(i);
      }
    }

    // 随机选择 N 个 typeB 卡牌替换为干扰释义
    typeBIndices.shuffle();
    final replaceCount = distractorCount.clamp(0, typeBIndices.length);

    final result = List<GameCard>.from(cards);
    final itemIds = cards.map((c) => c.itemId).toSet();

    // 收集本局游戏中所有可用的干扰释义
    // 从 allWords 中找那些既在本局内（itemId 匹配），又不是目标词的释义
    final distractorDefinitions = <String>[];
    for (final w in allWords) {
      if (itemIds.contains(w.id) && w.definition.isNotEmpty) {
        distractorDefinitions.add(w.definition.first);
      }
    }

    for (var i = 0; i < replaceCount; i++) {
      final targetIndex = typeBIndices[i];
      final originalItemId = result[targetIndex].itemId;

      // 找到本局内其他词的释义作为干扰
      final otherDefinitions = distractorDefinitions.where((def) {
        // 排除自身释义
        final isOwnDef = result.any(
          (c) =>
              c.itemId == originalItemId &&
              c.type == CardType.typeB &&
              c.text == def,
        );
        return !isOwnDef;
      }).toList();

      if (otherDefinitions.isNotEmpty) {
        otherDefinitions.shuffle();
        // 替换释义文本，但保留原 itemId（匹配逻辑不变，只是文本显示干扰）
        result[targetIndex] = result[targetIndex].copyWith(
          text: otherDefinitions.first,
        );
      }
    }

    return result;
  }

  /// 检查是否需要显示 Hint（连续3次错误）
  static bool shouldShowHint(int consecutiveErrors) {
    return consecutiveErrors >= 3;
  }
}
