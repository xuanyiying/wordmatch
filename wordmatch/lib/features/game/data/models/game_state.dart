import 'package:wordmatch/features/game/data/models/game_card.dart';

/// 游戏状态
enum GameStatus { idle, playing, paused, completed, failed }

/// 网格规格（由 pairCount 推导：pairCount > 12 → large，否则 small）
enum GridSize { small, large }

/// 从配对数推导网格规格
GridSize gridSizeFromPairs(int pairCount) =>
    pairCount > 12 ? GridSize.large : GridSize.small;

/// 游戏状态管理
class GameState {
  final GameStatus status;
  final GridSize gridSize;
  final int pairCount;
  final List<GameCard> cards;
  final int? selectedIndex;
  final int matchedCount;
  final int totalPairs;
  final int combo;
  final int maxCombo;
  final int wrongCount;
  final Duration elapsed;
  final int score;
  final Set<String> matchedItemIds;

  // 每个词的匹配表现追踪：itemId → (matchTimeMs, errorCount, usedHint, soundTapCount, rootLensTapCount, aiMnemonicTapCount)
  final Map<String, ({
    int matchTimeMs,
    int errorCount,
    bool usedHint,
    int soundTapCount,
    int rootLensTapCount,
    int aiMnemonicTapCount,
  })> wordPerformance;

  // 领域上下文信息
  final String? domainId;
  final String? domainName;
  final String typeALabel;
  final String typeBLabel;

  // 最近一次匹配成功的扩展信息（用于 UI 展示知识卡片）
  final Map<String, dynamic>? lastMatchedExtra;

  const GameState({
    this.status = GameStatus.idle,
    this.gridSize = GridSize.small,
    this.pairCount = 8,
    this.cards = const [],
    this.selectedIndex,
    this.matchedCount = 0,
    this.totalPairs = 0,
    this.combo = 0,
    this.maxCombo = 0,
    this.wrongCount = 0,
    this.elapsed = Duration.zero,
    this.score = 0,
    this.matchedItemIds = const <String>{},
    this.wordPerformance = const {},
    this.domainId,
    this.domainName,
    this.typeALabel = 'A',
    this.typeBLabel = 'B',
    this.lastMatchedExtra,
  });

  /// 是否已全部消除
  bool get isAllMatched => matchedCount >= totalPairs && totalPairs > 0;

  /// 正确率
  double get accuracy {
    final total = matchedCount + wrongCount;
    if (total == 0) return 0;
    return matchedCount / total;
  }

  GameState copyWith({
    GameStatus? status,
    GridSize? gridSize,
    int? pairCount,
    List<GameCard>? cards,
    Object? selectedIndex = _sentinel,
    int? matchedCount,
    int? totalPairs,
    int? combo,
    int? maxCombo,
    int? wrongCount,
    Duration? elapsed,
    int? score,
    Set<String>? matchedItemIds,
    Map<String, ({
      int matchTimeMs,
      int errorCount,
      bool usedHint,
      int soundTapCount,
      int rootLensTapCount,
      int aiMnemonicTapCount,
    })>? wordPerformance,
    String? domainId,
    Object? domainName = _sentinel,
    String? typeALabel,
    String? typeBLabel,
    Object? lastMatchedExtra = _sentinel,
  }) =>
      GameState(
        status: status ?? this.status,
        gridSize: gridSize ?? this.gridSize,
        pairCount: pairCount ?? this.pairCount,
        cards: cards ?? this.cards,
        selectedIndex: selectedIndex == _sentinel
            ? this.selectedIndex
            : selectedIndex as int?,
        matchedCount: matchedCount ?? this.matchedCount,
        totalPairs: totalPairs ?? this.totalPairs,
        combo: combo ?? this.combo,
        maxCombo: maxCombo ?? this.maxCombo,
        wrongCount: wrongCount ?? this.wrongCount,
        elapsed: elapsed ?? this.elapsed,
        score: score ?? this.score,
        matchedItemIds: matchedItemIds ?? this.matchedItemIds,
        wordPerformance: wordPerformance ?? this.wordPerformance,
        domainId: domainId ?? this.domainId,
        domainName:
            domainName == _sentinel ? this.domainName : domainName as String?,
        typeALabel: typeALabel ?? this.typeALabel,
        typeBLabel: typeBLabel ?? this.typeBLabel,
        lastMatchedExtra: lastMatchedExtra == _sentinel
            ? this.lastMatchedExtra
            : lastMatchedExtra as Map<String, dynamic>?,
      );
}

const _sentinel = Object();
