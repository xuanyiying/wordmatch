import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordmatch/features/game/data/models/game_card.dart';
import 'package:wordmatch/features/game/data/models/game_state.dart';
import 'package:wordmatch/features/game/domain/services/difficulty_service.dart';
import 'package:wordmatch/features/game/domain/services/match_service.dart';
import 'package:wordmatch/features/learning/data/repositories/progress_storage.dart';
import 'package:wordmatch/features/learning/domain/services/sm2_service.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';
import 'package:wordmatch/features/wordbook/data/repositories/wordbook_repository.dart';
import 'package:wordmatch/shared/utils/audio_player.dart';
import 'package:wordmatch/shared/utils/haptic_util.dart';

/// 词库仓库 Provider
final wordbookRepositoryProvider = Provider<WordbookRepository>((ref) {
  return WordbookRepository();
});

/// 当前词库 ID Notifier（带持久化）
class BookIdNotifier extends Notifier<String> {
  static const _prefsKey = 'current_book_id';
  static const _defaultBookId = 'gaokao';

  @override
  String build() {
    _loadFromPrefs();
    return _defaultBookId;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && saved.isNotEmpty) {
        state = saved;
      }
    } catch (_) {
      // 读取失败时保持默认值
    }
  }

  Future<void> setBookId(String bookId) async {
    state = bookId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, bookId);
    } catch (_) {
      // 写入失败时静默忽略（至少内存状态已更新）
    }
  }
}

/// 当前词库 ID Provider
final currentBookIdProvider =
    NotifierProvider<BookIdNotifier, String>(BookIdNotifier.new);

/// 当前词库列表 Provider
final wordListProvider = FutureProvider<List<Word>>((ref) async {
  final repo = ref.watch(wordbookRepositoryProvider);
  final bookId = ref.watch(currentBookIdProvider);
  return repo.loadBook(bookId);
});

/// 进度存储 Provider
final progressStorageProvider = Provider<ProgressStorage>((ref) {
  return ProgressStorage();
});

/// 游戏状态 Provider
final gameNotifierProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

/// 游戏状态管理
class GameNotifier extends Notifier<GameState> {
  // 追踪每个词的错误次数（itemId → 错误次数）
  final Map<String, int> _wordErrors = {};
  // 追踪本局使用过提示的单词（itemId 集合）。
  // 提示只影响被提示的那个词，避免污染整局所有单词的 SM-2 评分。
  final Set<String> _hintedItemIds = {};
  // 追踪每个词的首次选中时间（itemId → 选中第一张卡的时间）
  final Map<String, DateTime> _wordFirstSelectTime = {};
  // 追踪每个词的点发音次数
  final Map<String, int> _wordSoundTaps = {};
  // 追踪每个词的查词根透视镜次数
  final Map<String, int> _wordRootLensTaps = {};
  // 追踪每个词的查AI助记次数
  final Map<String, int> _wordAiMnemonicTaps = {};
  // 游戏计时器
  Stopwatch? _stopwatch;
  Timer? _elapsedTimer;

  @override
  GameState build() {
    // 当 provider 被重建时清理计时器
    ref.onDispose(() {
      _elapsedTimer?.cancel();
      _stopwatch?.stop();
    });
    return const GameState();
  }

  /// 启动游戏计时器
  void _startTimer() {
    _stopwatch = Stopwatch()..start();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_stopwatch != null && _stopwatch!.isRunning) {
        state = state.copyWith(elapsed: _stopwatch!.elapsed);
      }
    });
  }

  /// 停止游戏计时器
  void _stopTimer() {
    _stopwatch?.stop();
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  /// 从词库初始化游戏（英中模式，向后兼容）
  /// 默认标签为"英文"/"中文"，领域模式由 startDomainGame 设置
  void startGame(List<Word> words, int pairCount) {
    _resetTracking();
    _startTimer();
    final gridSize = gridSizeFromPairs(pairCount);
    final selectedWords = List<Word>.from(words);
    selectedWords.shuffle();
    final takenWords = selectedWords.take(pairCount).toList();

    final cards = <GameCard>[];
    for (final w in takenWords) {
      // typeA → 英文，typeB → 中文
      cards.add(GameCard.typeA(
        itemId: w.id,
        text: w.word,
        phonetic: w.phoneticUs,
      ));
      cards.add(GameCard.typeB(
        itemId: w.id,
        text: w.definition.first,
      ));
    }

    // 随机排列
    cards.shuffle();

    // 设置网格索引
    for (var i = 0; i < cards.length; i++) {
      cards[i] = cards[i].copyWith(gridIndex: i);
    }

    // 根据历史正确率动态添加干扰项（正确率 > 90% 时增加难度）
    final storage = ref.read(progressStorageProvider);
    final allProgress = storage.getAllProgress();
    final accuracy = _calculateHistoricalAccuracy(allProgress);
    final adjustedCards =
        DifficultyService.addDistractors(cards, words, accuracy);

    // 干扰项可能修改了文本，需重新设置索引
    for (var i = 0; i < adjustedCards.length; i++) {
      adjustedCards[i] = adjustedCards[i].copyWith(gridIndex: i);
    }

    state = GameState(
      status: GameStatus.playing,
      gridSize: gridSize,
      pairCount: pairCount,
      cards: adjustedCards,
      totalPairs: pairCount,
      domainId: 'english',
      domainName: '英语词汇',
      typeALabel: '英文',
      typeBLabel: '中文',
    );
  }

  /// 计算历史正确率
  double _calculateHistoricalAccuracy(List<WordProgress> allProgress) {
    if (allProgress.isEmpty) return 0.0;
    final mastered = allProgress.where((p) => p.isMastered).length;
    return mastered / allProgress.length;
  }

  /// 重置追踪状态
  void _resetTracking() {
    _wordErrors.clear();
    _hintedItemIds.clear();
    _wordFirstSelectTime.clear();
    _wordSoundTaps.clear();
    _wordRootLensTaps.clear();
    _wordAiMnemonicTaps.clear();
  }

  /// 点击卡牌
  void tapCard(int index) {
    if (state.status != GameStatus.playing) return;
    if (index < 0 || index >= state.cards.length) return;

    final cards = List<GameCard>.from(state.cards);
    final tappedCard = cards[index];

    // 已消除则忽略
    if (tappedCard.isMatched) return;

    // 每次点击时清除上一次匹配的扩展信息
    final shouldClearLastMatched = state.lastMatchedExtra != null;

    if (state.selectedIndex == null) {
      // 选中第一张卡牌
      cards[index] = tappedCard.copyWith(state: CardState.selected);
      // 记录该词首次选中时间（用于计算匹配耗时）
      _wordFirstSelectTime[tappedCard.itemId] = DateTime.now();
      state = state.copyWith(
        cards: cards,
        selectedIndex: index,
        lastMatchedExtra:
            shouldClearLastMatched ? null : state.lastMatchedExtra,
      );
    } else if (state.selectedIndex == index) {
      // 再次点击同一张卡牌，取消选中
      cards[index] = tappedCard.copyWith(state: CardState.revealed);
      state = state.copyWith(
        cards: cards,
        selectedIndex: null,
        lastMatchedExtra:
            shouldClearLastMatched ? null : state.lastMatchedExtra,
      );
    } else {
      // 选中第二张卡牌，检查匹配
      final firstIndex = state.selectedIndex!;
      final firstCard = cards[firstIndex];

      final matchResult = MatchService.checkMatch(
        firstCard: firstCard,
        secondCard: tappedCard,
      );

      if (matchResult.isMatch) {
        // 匹配成功 - 获取扩展信息（优先从 typeA 卡牌获取）
        final matchedExtra = firstCard.extra ?? tappedCard.extra;

        // 记录该词的匹配表现
        final itemId = tappedCard.itemId;
        final firstSelectTime = _wordFirstSelectTime[itemId];
        final matchTimeMs = firstSelectTime != null
            ? DateTime.now().difference(firstSelectTime).inMilliseconds
            : 3000; // 回退默认值
        final errorCount = _wordErrors[itemId] ?? 0;
        final newWordPerformance = Map<
            String,
            ({
              int matchTimeMs,
              int errorCount,
              bool usedHint,
              int soundTapCount,
              int rootLensTapCount,
              int aiMnemonicTapCount,
            })>.from(state.wordPerformance);
        newWordPerformance[itemId] = (
          matchTimeMs: matchTimeMs,
          errorCount: errorCount,
          // 只标记被提示过的词，避免提示污染整局所有单词的 SM-2 评分
          usedHint: _hintedItemIds.contains(itemId),
          soundTapCount: _wordSoundTaps[itemId] ?? 0,
          rootLensTapCount: _wordRootLensTaps[itemId] ?? 0,
          aiMnemonicTapCount: _wordAiMnemonicTaps[itemId] ?? 0,
        );

        final newCombo = state.combo + 1;
        final newMaxCombo =
            newCombo > state.maxCombo ? newCombo : state.maxCombo;
        final newScore = state.score + (10 + newCombo * 5);
        final newMatchedItemIds = Set<String>.from(state.matchedItemIds)
          ..add(tappedCard.itemId);

        // 先将卡片设为 matched 状态（让 UI 播放爆裂动画）
        cards[firstIndex] = firstCard.copyWith(state: CardState.matched);
        cards[index] = tappedCard.copyWith(state: CardState.matched);

        state = state.copyWith(
          cards: cards,
          selectedIndex: null,
          matchedCount: state.matchedCount + 1,
          combo: newCombo,
          maxCombo: newMaxCombo,
          score: newScore,
          matchedItemIds: newMatchedItemIds,
          wordPerformance: newWordPerformance,
          lastMatchedExtra: matchedExtra,
        );

        // 音效与震动反馈
        if (newCombo >= 3) {
          AudioPlayerUtil.playCombo();
          HapticUtil.comboHit();
        } else {
          AudioPlayerUtil.playMatchSuccess();
          HapticUtil.matchSuccess();
        }

        // 匹配成功后，自动播放英文单词发音（如果是英语词汇）
        final isEnglish = state.domainId == 'english' ||
            state.domainId?.startsWith('wrong_words_') == true;
        if (isEnglish) {
          final englishWord = firstCard.type == CardType.typeA
              ? firstCard.text
              : tappedCard.text;
          AudioPlayerUtil.speakWord(englishWord);
        }

        // 延迟 400ms 后从列表中移除卡片（给爆裂动画留出时间）
        Future.delayed(const Duration(milliseconds: 400), () {
          // provider 已被 dispose（页面退出）时不再写 state，避免异常
          if (!ref.mounted) return;
          final currentState = ref.container.read(gameNotifierProvider);
          if (!currentState.cards.any((c) => c.isMatched)) return;

          // 每行固定 4 个卡片
          const gridCols = 4;

          // 快照剩余卡牌的旧网格位置
          final oldPositions = <String, Offset>{};
          for (final card in currentState.cards) {
            if (!card.isMatched) {
              final row = card.gridIndex ~/ gridCols;
              final col = card.gridIndex % gridCols;
              oldPositions[card.itemId] =
                  Offset(col.toDouble(), row.toDouble());
            }
          }

          // 移除已消除卡片并重新编号
          final currentCards = List<GameCard>.from(currentState.cards);
          currentCards.removeWhere((c) => c.isMatched);
          for (var i = 0; i < currentCards.length; i++) {
            final card = currentCards[i];
            final newCol = i % gridCols;
            final newRow = i ~/ gridCols;
            final oldPos = oldPositions[card.itemId] ??
                Offset(newCol.toDouble(), newRow.toDouble());
            final delta = Offset(oldPos.dx - newCol, oldPos.dy - newRow);
            currentCards[i] = card.copyWith(
              gridIndex: i,
              position: delta, // 偏移量：从旧位置到新位置的差值
            );
          }

          // 检查是否全部消除
          final allMatched = currentCards.isEmpty;
          if (allMatched) {
            _stopTimer();
            state = currentState.copyWith(
                cards: currentCards, status: GameStatus.completed);
            AudioPlayerUtil.playLevelComplete();
            HapticUtil.levelComplete();
            _saveGameProgress();
          } else {
            state = currentState.copyWith(cards: currentCards);
          }

          // 滑动动画完成后，重置位置偏移为零
          if (!allMatched) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!ref.mounted) return;
              final s = ref.container.read(gameNotifierProvider);
              final resetCards = s.cards
                  .map((c) => c.copyWith(position: Offset.zero))
                  .toList();
              state = s.copyWith(cards: resetCards);
            });
          }
        });
      } else {
        // 匹配失败
        cards[firstIndex] = firstCard.copyWith(state: CardState.shaking);
        cards[index] = tappedCard.copyWith(state: CardState.shaking);

        // 追踪每个词的错误次数
        _wordErrors[firstCard.itemId] =
            (_wordErrors[firstCard.itemId] ?? 0) + 1;
        _wordErrors[tappedCard.itemId] =
            (_wordErrors[tappedCard.itemId] ?? 0) + 1;

        // 记录错词到 ProgressStorage
        _recordWrongWords(firstCard, tappedCard);

        state = state.copyWith(
          cards: cards,
          selectedIndex: null,
          combo: 0,
          wrongCount: state.wrongCount + 1,
          lastMatchedExtra: null,
        );

        // 音效与震动反馈
        AudioPlayerUtil.playMatchFail();
        HapticUtil.matchFail();

        // 抖动结束后恢复为 revealed
        // 先记录 shaking 卡片的索引，避免在 Future 回调中访问 state（Riverpod 3.x 不允许自依赖）
        final shakingIndices = <int>[];
        for (var i = 0; i < cards.length; i++) {
          if (cards[i].state == CardState.shaking) {
            shakingIndices.add(i);
          }
        }
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!ref.mounted) return;
          if (shakingIndices.isEmpty) return;
          // 通过 container 读取当前状态，避免自依赖断言
          final currentState = ref.container.read(gameNotifierProvider);
          final currentCards = List<GameCard>.from(currentState.cards);
          // 仅更新仍存在的索引位置的 shaking 卡片
          for (final idx in shakingIndices) {
            if (idx < currentCards.length &&
                currentCards[idx].state == CardState.shaking) {
              currentCards[idx] =
                  currentCards[idx].copyWith(state: CardState.revealed);
            }
          }
          state = currentState.copyWith(cards: currentCards);
        });
      }
    }
  }

  /// 游戏完成后保存 SM-2 进度
  Future<void> _saveGameProgress() async {
    final storage = ref.read(progressStorageProvider);
    await storage.init();

    // 在 await 之前捕获当前状态，避免自依赖问题
    final currentState = ref.container.read(gameNotifierProvider);
    final matchedItemIds = currentState.matchedItemIds;

    // 为每个匹配的单词更新 SM-2 进度
    final bookId = ref.read(currentBookIdProvider);
    for (final itemId in matchedItemIds) {
      var progress = storage.getProgress(itemId);
      progress ??= WordProgress.newWord(itemId, bookId);

      // 从每词表现追踪中获取实际匹配数据
      final perf = currentState.wordPerformance[itemId];
      final quality = Sm2Service.calculateQuality(
        matchTimeMs: perf?.matchTimeMs ?? 3000,
        errorCount: perf?.errorCount ?? 0,
        usedHint: perf?.usedHint ?? false,
        soundTapCount: perf?.soundTapCount ?? 0,
        rootLensTapCount: perf?.rootLensTapCount ?? 0,
        aiMnemonicTapCount: perf?.aiMnemonicTapCount ?? 0,
      );

      progress = Sm2Service.updateProgress(progress, quality);
      await storage.updateProgress(progress);

      // 错题重练模式中，匹配成功则从错词本移除
      if (currentState.domainId?.startsWith('wrong_words_') == true) {
        await storage.removeWrongWord(itemId);
      }
    }
  }

  /// 重置游戏
  void resetGame() {
    _stopTimer();
    state = const GameState();
  }

  /// 标记某个词使用了提示道具（提示只影响该词的 SM-2 评分）
  void markHintUsed(String itemId) {
    _hintedItemIds.add(itemId);
  }

  /// 标记某个词点了发音
  void markSoundTapped(String itemId) {
    _wordSoundTaps[itemId] = (_wordSoundTaps[itemId] ?? 0) + 1;
  }

  /// 标记某个词查了词根透视镜
  void markRootLensTapped(String itemId) {
    _wordRootLensTaps[itemId] = (_wordRootLensTaps[itemId] ?? 0) + 1;
  }

  /// 标记某个词查了AI助记
  void markAiMnemonicTapped(String itemId) {
    _wordAiMnemonicTaps[itemId] = (_wordAiMnemonicTaps[itemId] ?? 0) + 1;
  }

  /// 记录错词到 ProgressStorage
  Future<void> _recordWrongWords(
      GameCard firstCard, GameCard secondCard) async {
    final storage = ref.read(progressStorageProvider);
    if (!storage.isInitialized) await storage.init();

    final bookId = ref.read(currentBookIdProvider);

    // 记录两个词都错了（用户混淆了它们）
    final context = '${firstCard.text} ↔ ${secondCard.text}';
    await storage.addWrongWord(
        wordId: firstCard.itemId, bookId: bookId, context: context);
    await storage.addWrongWord(
        wordId: secondCard.itemId, bookId: bookId, context: context);
  }

  /// 从错词本初始化游戏（错题重练模式）
  Future<void> startWrongWordGame(List<Word> allWords, int pairCount) async {
    _resetTracking();
    _startTimer();
    final gridSize = gridSizeFromPairs(pairCount);
    final storage = ref.read(progressStorageProvider);
    if (!storage.isInitialized) await storage.init();

    final wrongWords = storage.getWrongWords();
    if (wrongWords.isEmpty) {
      state = const GameState();
      return;
    }

    // 从错词 ID 中匹配完整的 Word 对象
    final wrongWordIds = wrongWords.map((w) => w.wordId).toSet();
    final matchedWords =
        allWords.where((w) => wrongWordIds.contains(w.id)).toList();

    if (matchedWords.isEmpty) {
      state = const GameState();
      return;
    }

    // 如果错词不足，补充随机词
    matchedWords.shuffle();
    final takenWords = matchedWords.take(pairCount).toList();
    if (takenWords.length < pairCount) {
      final remaining = allWords
          .where((w) => !wrongWordIds.contains(w.id))
          .toList()
        ..shuffle();
      takenWords.addAll(remaining.take(pairCount - takenWords.length));
    }

    final cards = <GameCard>[];
    for (final w in takenWords) {
      cards.add(
          GameCard.typeA(itemId: w.id, text: w.word, phonetic: w.phoneticUs));
      cards.add(GameCard.typeB(itemId: w.id, text: w.definition.first));
    }

    cards.shuffle();
    for (var i = 0; i < cards.length; i++) {
      cards[i] = cards[i].copyWith(gridIndex: i);
    }

    final bookId = ref.read(currentBookIdProvider);
    state = GameState(
      status: GameStatus.playing,
      gridSize: gridSize,
      pairCount: pairCount,
      cards: cards,
      totalPairs: pairCount.clamp(0, takenWords.length),
      domainId: 'wrong_words_$bookId',
      domainName: '错题重练',
      typeALabel: '英文',
      typeBLabel: '中文',
    );
  }

  /// 执行提示操作：选中一对可消除的卡牌
  /// 返回提示的卡牌文本（用于 SnackBar 显示），如果无可消除对则返回 null
  HintResult? performHint() {
    if (state.status != GameStatus.playing) return null;

    final hintPair = DifficultyService.findHintPair(state.cards);
    if (hintPair == null) return null;

    final typeAIndex = hintPair[0];
    final typeBIndex = hintPair[1];
    final typeACard = state.cards[typeAIndex];
    final typeBCard = state.cards[typeBIndex];

    // 记录被提示的词，使其 SM-2 评分按"使用提示"处理（仅影响该词，不污染整局）
    _hintedItemIds.add(typeBCard.itemId);

    // 如果当前已有选中卡片，先取消选中
    if (state.selectedIndex != null) {
      final cards = List<GameCard>.from(state.cards);
      cards[state.selectedIndex!] = cards[state.selectedIndex!].copyWith(
        state: CardState.revealed,
      );
      state = state.copyWith(cards: cards, selectedIndex: null);
    }

    // 选中 typeA 卡牌
    tapCard(typeAIndex);

    // 返回提示信息（调用方延迟选中第二张）
    return HintResult(
      typeAText: typeACard.text,
      typeBText: typeBCard.text,
      typeBItemId: typeBCard.itemId,
    );
  }
}

/// 提示操作结果
class HintResult {
  final String typeAText;
  final String typeBText;
  final String typeBItemId;

  const HintResult({
    required this.typeAText,
    required this.typeBText,
    required this.typeBItemId,
  });
}
