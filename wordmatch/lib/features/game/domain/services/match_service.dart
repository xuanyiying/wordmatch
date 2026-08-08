import 'package:wordmatch/features/game/data/models/game_card.dart';

/// 匹配结果
class MatchResult {
  final bool isMatch;
  final String? message;

  const MatchResult({required this.isMatch, this.message});
}

/// 匹配服务：检查两张卡牌是否匹配
class MatchService {
  MatchService._();

  /// 检查两张卡牌是否匹配
  /// 规则：一张 typeA + 一张 typeB，且 itemId 相同
  static MatchResult checkMatch({
    required GameCard firstCard,
    required GameCard secondCard,
  }) {
    // 必须一张 typeA 一张 typeB
    if (firstCard.type == secondCard.type) {
      return const MatchResult(
        isMatch: false,
        message: '请选择不同类型的卡牌进行配对',
      );
    }

    // itemId 相同则匹配成功
    if (firstCard.itemId == secondCard.itemId) {
      return const MatchResult(isMatch: true);
    }

    return const MatchResult(isMatch: false);
  }
}
