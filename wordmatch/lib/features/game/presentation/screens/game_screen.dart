import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/core/constants/app_colors.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/core/constants/app_strings.dart';
import 'package:wordmatch/core/subscription/subscription_service.dart';
import 'package:wordmatch/core/subscription/upgrade_pro_dialog.dart';
import 'package:wordmatch/core/theme/card_theme.dart';
import 'package:wordmatch/core/theme/card_theme_providers.dart';
import 'package:wordmatch/core/theme/card_theme_registry.dart';
import 'package:wordmatch/features/game/data/models/game_card.dart';
import 'package:wordmatch/features/game/data/models/game_state.dart';
import 'package:wordmatch/features/game/data/repositories/game_provider.dart';
import 'package:wordmatch/features/game/domain/services/difficulty_service.dart';
import 'package:wordmatch/features/game/domain/services/root_engine.dart';
import 'package:wordmatch/features/game/domain/services/disambiguation_service.dart';
import 'package:wordmatch/features/learning/data/services/mnemonic_service.dart';
import 'package:wordmatch/features/learning/domain/services/plan_service.dart';
import 'package:wordmatch/features/game/presentation/widgets/combo_indicator.dart';
import 'package:wordmatch/features/game/presentation/widgets/grid_widget.dart';
import 'package:wordmatch/features/ai/data/services/ai_client.dart';
import 'package:wordmatch/features/ai/data/services/ai_learning_service.dart';
import 'package:wordmatch/features/game/presentation/widgets/match_burst_effect.dart';
import 'package:wordmatch/features/learning/presentation/widgets/ai_example_sentences.dart';
import 'package:wordmatch/features/game/presentation/widgets/game_background_painter.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';
import 'package:wordmatch/shared/utils/haptic_util.dart';
import 'package:wordmatch/shared/widgets/neumorphic_card.dart';

/// 游戏屏幕参数
class GameScreenArgs {
  /// 配对数量（4, 8, 12, 18 等）
  final int pairCount;
  final String bookId;

  /// 复习模式：仅使用这些词的ID
  final Set<String>? reviewWordIds;

  /// 新词巩固模式：仅使用这些词的ID
  final Set<String>? newWordIds;

  /// 是否标记今日消消乐任务完成（新词巩固模式为 true）
  final bool markDailyGameCompleted;

  const GameScreenArgs({
    required this.pairCount,
    required this.bookId,
    this.reviewWordIds,
    this.newWordIds,
    this.markDailyGameCompleted = false,
  });

  factory GameScreenArgs.defaultArgs() =>
      const GameScreenArgs(pairCount: 8, bookId: 'gaokao');

  /// 便捷：从 pairCount 推导 GridSize
  GridSize get gridSize => gridSizeFromPairs(pairCount);
}

/// 核心游戏屏幕
class GameScreen extends ConsumerStatefulWidget {
  final GameScreenArgs args;

  const GameScreen({super.key, required this.args});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  int _consecutiveErrors = 0;
  bool _hintUsed = false;

  // 匹配信息浮层相关状态
  String? _matchInfoText;
  bool _matchInfoVisible = false;

  // 匹配爆裂效果
  final List<MatchBurstEffect> _burstEffects = [];

  // 卡牌 GlobalKey 列表，用于通过 RenderBox 获取卡牌屏幕坐标
  final List<GlobalKey> _cardKeys = [];

  // 动画背景
  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      duration: const Duration(milliseconds: 10000),
      vsync: this,
    )..repeat();
    // 异步加载词库并启动游戏
    Future.microtask(() => _startGame());
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    // 单词消消乐模式
    _startWordGame();
  }

  /// 启动单词消消乐模式
  Future<void> _startWordGame() async {
    // 错题重练模式：状态已由错词本页面预置，直接进入，避免被重新生成覆盖
    final preState = ref.read(gameNotifierProvider);
    if (preState.status == GameStatus.playing &&
        preState.domainId?.startsWith('wrong_words_') == true) {
      return;
    }

    // 通过仓库直接加载词库并等待完成（与学习页一致，绕过 wordListProvider
    // 的异步状态），避免同步读取 AsyncValue 时词库仍在加载中导致游戏永不启动
    List<Word> words;
    try {
      words = await ref
          .read(wordbookRepositoryProvider)
          .loadBook(widget.args.bookId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('[GameScreen] 词库加载超时，返回空词库');
              return <Word>[];
            },
          );
    } catch (_) {
      words = [];
    }

    // 复习模式：仅使用 SM-2 筛选的到期复习词
    final reviewWordIds = widget.args.reviewWordIds;
    if (reviewWordIds != null && reviewWordIds.isNotEmpty) {
      words = words.where((w) => reviewWordIds.contains(w.id)).toList();
    }
    // 新词巩固模式：使用刚学过的新词
    else if (widget.args.newWordIds != null &&
        widget.args.newWordIds!.isNotEmpty) {
      words =
          words.where((w) => widget.args.newWordIds!.contains(w.id)).toList();
    }

    if (words.isNotEmpty) {
      ref
          .read(gameNotifierProvider.notifier)
          .startGame(words, widget.args.pairCount);
      _consecutiveErrors = 0;
      _hintUsed = false;
      return;
    }

    // 词库为空（加载失败或过滤后无词）：提示并退出，避免页面永久停留在加载态
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('没有可用的单词，请先学习新词后再来')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final gameState = ref.watch(gameNotifierProvider);
    final themeType = ref.watch(cardThemeTypeProvider);
    final themeData = CardThemeRegistry.get(themeType);
    final variant = themeData.resolve(context);

    // 监听匹配成功事件，更新信息浮层 + 触发爆裂效果
    ref.listen<GameState>(gameNotifierProvider, (prev, next) {
      if (next.lastMatchedExtra != null &&
          next.lastMatchedExtra != prev?.lastMatchedExtra) {
        // 新的匹配成功，格式化并显示信息
        final extra = next.lastMatchedExtra!;
        final infoText = extra.values.whereType<String>().join(' · ');
        if (infoText.isNotEmpty) {
          setState(() {
            _matchInfoText = infoText;
            _matchInfoVisible = true;
          });
          // 2.5秒后自动隐藏
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (!mounted) return;
            setState(() {
              _matchInfoVisible = false;
            });
          });
        }

        // 触发匹配爆裂效果：找到 matched 状态的卡片
        final matchedCards = next.cards.where((c) => c.isMatched).toList();
        if (matchedCards.isNotEmpty && prev != null) {
          final prevMatched = prev.cards.where((c) => c.isMatched).length;
          if (matchedCards.length > prevMatched) {
            _triggerBurstEffects(matchedCards, variant);
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: context.appColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(AppStrings.appName),
        actions: [
          // AI 助记卡道具
          _buildItemButton(
            icon: Icons.auto_stories,
            tooltip: 'AI助记卡',
            onPressed: () => _showMnemonicCard(gameState),
          ),
          // 词根透视镜道具
          _buildItemButton(
            icon: Icons.visibility,
            tooltip: '词根透视镜',
            onPressed: () => _showRootLens(context, gameState),
          ),
          // 提示道具
          _buildItemButton(
            icon: Icons.lightbulb_outline,
            tooltip: '提示',
            onPressed: () => _showHint(gameState),
          ),
          // 分数显示
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${gameState.score}分',
                style: TextStyle(
                  color: colors.mintDeep,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 暗色主题背景渐变
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: variant.gameBgGradient,
              ),
            ),
          ),
          // 主题色辉光（缓慢呼吸移动）
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnimController,
              builder: (context, child) {
                final t = _bgAnimController.value;
                final glowCenterY = -0.3 + t * 0.2; // slowly shift from top
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.0, glowCenterY),
                      radius: 1.2 + t * 0.15,
                      colors: [
                        variant.gameBgGlow,
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 动画背景浮游元素
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnimController,
              builder: (context, child) {
                return CustomPaint(
                  painter: GameBackgroundPainter(
                    themeType: themeType,
                    elementColor: variant.ambientElementColor,
                    animationValue: _bgAnimController.value,
                  ),
                  size: MediaQuery.of(context).size,
                );
              },
            ),
          ),
          // 暗角叠加层
          const Positioned.fill(
            child: VignetteOverlay(color: Colors.black, intensity: 0.12),
          ),
          SafeArea(child: _buildBody(gameState, themeType)),
          // 匹配爆裂效果叠加层
          ..._burstEffects,
          // 匹配成功知识信息浮层
          if (_matchInfoText != null) _buildMatchInfoOverlay(),
          // 通关结算面板：居中显示，避免在长列表底部需要滚动
          if (gameState.status == GameStatus.completed)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: _buildCompletionPanel(gameState),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 触发匹配爆裂效果
  void _triggerBurstEffects(
      List<GameCard> matchedCards, CardThemeVariant variant) {
    final tt = ref.read(cardThemeTypeProvider);

    for (final card in matchedCards) {
      // 通过 GlobalKey + RenderBox 获取卡牌实际屏幕坐标
      final cardIndex = ref.read(gameNotifierProvider).cards.indexOf(card);
      Offset center;

      if (cardIndex >= 0 && cardIndex < _cardKeys.length) {
        final renderBox = _cardKeys[cardIndex].currentContext
            ?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final size = renderBox.size;
          final offset = renderBox.localToGlobal(Offset.zero);
          center = Offset(
            offset.dx + size.width / 2 - 50,
            offset.dy + size.height / 2 - 50,
          );
        } else {
          continue;
        }
      } else {
        continue;
      }

      final effect = MatchBurstEffect(
        center: center,
        themeType: tt,
        burstColors: variant.burstColors,
      );

      setState(() {
        _burstEffects.add(effect);
      });

      // Remove effect after animation
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() {
            _burstEffects.remove(effect);
          });
        }
      });
    }
  }

  /// 匹配成功知识信息浮层
  Widget _buildMatchInfoOverlay() {
    final colors = context.appColors;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 80,
      child: AnimatedSlide(
        offset: _matchInfoVisible ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _matchInfoVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colors.mintDeep.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: colors.mintDeep.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  size: 20,
                  color: colors.mintDeep,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _matchInfoText!,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final colors = context.appColors;
    return IconButton(
      icon: Icon(icon, color: colors.mintDeep),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  Widget _buildBody(GameState gameState, CardThemeType themeType) {
    if (gameState.status == GameStatus.idle) {
      return const Center(child: CircularProgressIndicator());
    }

    // 确保 _cardKeys 数量与当前卡牌数量一致
    while (_cardKeys.length < gameState.cards.length) {
      _cardKeys.add(GlobalKey());
    }
    if (_cardKeys.length > gameState.cards.length) {
      _cardKeys.removeRange(gameState.cards.length, _cardKeys.length);
    }

    // 18对=36张卡片=9行，超出屏幕高度时需要上下滚动
    return LayoutBuilder(
      builder: (context, constraints) {
        // 估算固定区域高度：状态栏 ~48 + Combo ~48 + 底部信息 ~80
        const fixedSectionsHeight = 176.0;
        final minGridHeight = constraints.maxHeight - fixedSectionsHeight;

        return SingleChildScrollView(
          child: Column(
            children: [
              // 进度与状态栏
              _buildStatusBar(gameState),

              // Combo 指示器
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ComboIndicator(combo: gameState.combo),
              ),

              // 消除网格：卡片少时填满可用空间，卡片多时自然延伸并支持滚动
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: minGridHeight > 0 ? minGridHeight : 0,
                ),
                child: GridWidget(
                  gameState: gameState,
                  themeType: themeType,
                  cardKeys: _cardKeys,
                  onCardTap: (index) {
                    _onCardTap(gameState, index);
                  },
                ),
              ),

              // 底部信息
              _buildBottomInfo(gameState),
            ],
          ),
        );
      },
    );
  }

  /// 卡牌点击处理（带错误计数）
  void _onCardTap(GameState gameState, int index) {
    if (gameState.status != GameStatus.playing) return;

    final card = gameState.cards[index];
    if (card.isMatched) return;

    // 如果是第二张卡牌的点击，检查是否匹配
    if (gameState.selectedIndex != null && gameState.selectedIndex != index) {
      final firstCard = gameState.cards[gameState.selectedIndex!];
      final matchResult =
          firstCard.itemId == card.itemId && firstCard.type != card.type;

      if (matchResult) {
        _consecutiveErrors = 0;
      } else {
        _consecutiveErrors++;
        // 显示消歧提示
        _showDisambiguationHint(firstCard, card);
      }
    }

    ref.read(gameNotifierProvider.notifier).tapCard(index);
  }

  /// 显示匹配失败的消歧提示
  void _showDisambiguationHint(GameCard firstCard, GameCard secondCard) {
    // 找到正确匹配的那对卡牌
    final gameState = ref.read(gameNotifierProvider);
    final correctPair = gameState.cards
        .where(
          (c) => c.itemId == firstCard.itemId && c.type == CardType.typeA,
        )
        .firstOrNull;
    final correctPairB = gameState.cards
        .where(
          (c) => c.itemId == firstCard.itemId && c.type == CardType.typeB,
        )
        .firstOrNull;

    if (correctPair == null || correctPairB == null) return;

    final hintText = DisambiguationService.generateShortHint(
      correctWord: correctPair.text,
      correctDefinition: correctPairB.text,
    );

    setState(() {
      _matchInfoText = hintText;
      _matchInfoVisible = true;
    });

    // 3秒后自动隐藏
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      setState(() {
        _matchInfoVisible = false;
      });
    });
  }

  /// 状态栏：进度、正确率
  Widget _buildStatusBar(GameState gameState) {
    final colors = context.appColors;
    final progress = gameState.totalPairs > 0
        ? gameState.matchedCount / gameState.totalPairs
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.pagePaddingH,
        vertical: 8,
      ),
      child: Row(
        children: [
          // 进度条
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colors.border.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  colors.mintDeep,
                ),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 已消除对数
          Text(
            '${gameState.matchedCount}/${gameState.totalPairs}',
            style: TextStyle(
              fontSize: 14,
              color: colors.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 底部信息栏
  Widget _buildBottomInfo(GameState gameState) {
    final colors = context.appColors;
    // 通关状态：结算面板已在 Stack 顶层作为 Overlay 居中显示，此处仅占位
    if (gameState.status == GameStatus.completed) {
      return const SizedBox(height: 24);
    }

    // 连续3次错误时显示提示建议
    final showHintSuggestion =
        DifficultyService.shouldShowHint(_consecutiveErrors);

    return Padding(
      padding: const EdgeInsets.all(AppSizes.pagePaddingH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHintSuggestion && !_hintUsed)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '连续出错啦，试试点击右上角💡提示？',
                style: TextStyle(
                  color: AppColors.accentOrange,
                  fontSize: 13,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app,
                  size: 16, color: colors.inkSoft),
              const SizedBox(width: 4),
              Text(
                '选择一${gameState.typeALabel}一${gameState.typeBLabel}配对消除',
                style: TextStyle(
                  color: colors.inkSoft,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 通关结算面板
  Widget _buildCompletionPanel(GameState gameState) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.mintDeep.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部装饰：完成图标
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colors.mintDeep.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: colors.mintDeep,
              size: 36,
            ),
          ),
          Text(
            AppStrings.levelComplete,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.mintDeep,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                  '得分', '${gameState.score}', colors.mintDeep),
              _buildStatItem(
                  '正确率',
                  '${(gameState.accuracy * 100).toStringAsFixed(0)}%',
                  AppColors.success),
              _buildStatItem(AppStrings.maxCombo, '${gameState.maxCombo}x',
                  colors.mintDeep),
            ],
          ),
          const SizedBox(height: 24),
          // 进入下一个学习任务（主按钮）
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                HapticUtil.buttonTap();
                await _markGameCompletedIfNeeded();
                if (!mounted) return;
                // 返回 'advance_next' 信号，由调用方（学习首页）推进计划并直接进入新词学习
                Navigator.of(context).pop('advance_next');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: colors.mintDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: const Text(
                '进入下一个学习任务',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 次操作按钮行
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await _markGameCompletedIfNeeded();
                    if (!mounted) return;
                    final dailyTask = _buildDailyTaskFromGame(gameState);
                    Navigator.of(context).pushReplacementNamed(
                      '/report',
                      arguments: dailyTask,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.mintDeep),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('查看报告'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticUtil.buttonTap();
                    ref.read(gameNotifierProvider.notifier).resetGame();
                    _startGame();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: colors.inkSoft.withValues(alpha: 0.3)),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '继续挑战',
                    style: TextStyle(color: colors.inkSoft),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 如果是新词巩固模式，标记今日消消乐任务完成
  Future<void> _markGameCompletedIfNeeded() async {
    if (!widget.args.markDailyGameCompleted) return;
    final storage = ref.read(progressStorageProvider);
    final taskState = storage.getDailyTaskState();
    if (taskState != null &&
        taskState.learningCompleted &&
        !taskState.gameCompleted) {
      final updated = taskState.copyWith(gameCompleted: true);
      await storage.saveDailyTaskState(updated);
    }
  }

  /// 从游戏结果构建 DailyTask
  DailyTask _buildDailyTaskFromGame(GameState gameState) {
    return DailyTask(
      completedNew: gameState.matchedCount,
      completedReview: 0,
      wrongCount: gameState.wrongCount,
      score: gameState.score,
      maxCombo: gameState.maxCombo,
      newWordsTarget: gameState.totalPairs,
      reviewWordsTarget: 0,
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    final colors = context.appColors;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.inkSoft,
          ),
        ),
      ],
    );
  }

  /// AI 助记卡：显示当前选中/最近匹配单词的助记内容
  void _showMnemonicCard(GameState gameState) {
    HapticUtil.buttonTap();

    // 找目标单词：优先选中的 typeA 卡牌
    String? targetWord;
    String? targetItemId;
    if (gameState.selectedIndex != null) {
      final selectedCard = gameState.cards[gameState.selectedIndex!];
      if (selectedCard.type == CardType.typeA) {
        targetWord = selectedCard.text;
        targetItemId = selectedCard.itemId;
      }
    }

    // 如果没有选中 typeA，找任意 typeA
    targetWord ??= gameState.cards
        .where((c) => c.type == CardType.typeA && !c.isMatched)
        .map((c) => c.text)
        .firstOrNull;
    targetItemId ??= gameState.cards
        .where((c) => c.type == CardType.typeA && !c.isMatched)
        .map((c) => c.itemId)
        .firstOrNull;

    if (targetWord == null || targetItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无可查看的单词')),
      );
      return;
    }

    final selectedWord = targetWord;
    final selectedWordId = targetItemId;

    // 记录"查AI助记"行为信号（影响该词 SM-2 评分）
    ref.read(gameNotifierProvider.notifier).markAiMnemonicTapped(selectedWordId);

    showDialog(
      context: context,
      builder: (ctx) => _MnemonicCardDialog(
        wordId: selectedWordId,
        word: selectedWord,
      ),
    );
  }

  /// 词根透视镜：显示当前选中卡牌单词的词根拆解
  void _showRootLens(BuildContext context, GameState gameState) {
    HapticUtil.buttonTap();

    // 找到当前选中的卡牌（已选中的 typeA 卡牌）
    String? targetWord;
    String? targetItemId;
    if (gameState.selectedIndex != null) {
      final selectedCard = gameState.cards[gameState.selectedIndex!];
      if (selectedCard.type == CardType.typeA) {
        targetWord = selectedCard.text;
        targetItemId = selectedCard.itemId;
      }
    }

    // 如果没有选中的 typeA 卡牌，找所有已选中的 typeA 卡牌
    targetWord ??= gameState.cards
        .where((c) => c.type == CardType.typeA && c.state == CardState.selected)
        .map((c) => c.text)
        .firstOrNull;
    targetItemId ??= gameState.cards
        .where((c) => c.type == CardType.typeA && c.state == CardState.selected)
        .map((c) => c.itemId)
        .firstOrNull;

    // 如果还是没有，取任意一张 typeA 卡牌
    targetWord ??= gameState.cards
        .where((c) => c.type == CardType.typeA)
        .map((c) => c.text)
        .firstOrNull;
    targetItemId ??= gameState.cards
        .where((c) => c.type == CardType.typeA)
        .map((c) => c.itemId)
        .firstOrNull;

    if (targetWord == null || targetItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先选中一张${gameState.typeALabel}卡牌')),
      );
      return;
    }

    // 记录"查词根"行为信号（影响该词 SM-2 评分）
    ref.read(gameNotifierProvider.notifier).markRootLensTapped(targetItemId);

    final breakdown = RootEngine.analyze(targetWord);

    showDialog(
      context: context,
      builder: (ctx) => _RootLensDialog(
        word: targetWord!,
        breakdown: breakdown,
      ),
    );
  }

  /// 提示：高亮一对可消除的卡牌
  void _showHint(GameState gameState) {
    if (gameState.status != GameStatus.playing) return;

    final result = ref.read(gameNotifierProvider.notifier).performHint();
    if (result == null) return;

    _hintUsed = true;
    HapticUtil.buttonTap();

    // 延迟选中第二张（模拟提示效果）
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final currentState = ref.read(gameNotifierProvider);
      // 守卫：仅当用户未在延迟窗口内自行操作时才自动选中
      if (currentState.selectedIndex == null) return;
      // 通过 itemId 在当前卡片列表中找到第二张卡片
      final typeBCard = currentState.cards.where(
          (c) => c.itemId == result.typeBItemId && c.type == CardType.typeB);
      if (typeBCard.isEmpty) return;
      final chiIdx = currentState.cards.indexOf(typeBCard.first);
      if (chiIdx >= 0) {
        ref.read(gameNotifierProvider.notifier).tapCard(chiIdx);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('提示：${result.typeAText} ↔ ${result.typeBText}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// AI 助记卡弹窗
class _MnemonicCardDialog extends ConsumerStatefulWidget {
  final String wordId;
  final String word;

  const _MnemonicCardDialog({
    required this.wordId,
    required this.word,
  });

  @override
  ConsumerState<_MnemonicCardDialog> createState() =>
      _MnemonicCardDialogState();
}

class _MnemonicCardDialogState extends ConsumerState<_MnemonicCardDialog> {
  Mnemonic? _mnemonic;
  List<String> _definition = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // 1. 查找本地助记
    var mnemonic = MnemonicService.getMnemonicSync(widget.wordId);

    // 2. 查找单词释义
    List<String> definition = [];
    try {
      final words = await ref.read(wordListProvider.future);
      final matched =
          words.where((w) => w.id == widget.wordId).firstOrNull;
      definition = matched?.definition ?? [];
    } catch (_) {
      definition = [];
    }

    // 3. 若本地无助记，尝试 AI 生成
    if (mnemonic == null && definition.isNotEmpty) {
      try {
        mnemonic = await AiLearningService.generateMnemonic(
          widget.wordId,
          definition,
        );
        if (mnemonic == null && AiClient.isConfigured && mounted) {
          final q = await SubscriptionService.getAiQuota();
          if (!mounted) return;
          if (q.$1 >= q.$2 && q.$2 != -1) {
            showUpgradeProDialog(context, reason: '今日 AI 额度已用完');
          }
        }
      } catch (_) {
        mnemonic = null;
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _definition = definition;
      _mnemonic = mnemonic;
      if (mnemonic == null && AiClient.isConfigured) {
        _error = 'AI 助记生成失败，请稍后重试';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(Icons.auto_stories,
                    color: colors.mintDeep, size: 24),
                const SizedBox(width: 8),
                Text(
                  'AI 助记卡',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.mintDeep,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 单词
            Center(
              child: Text(
                widget.word,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading) ...[
              Center(
                child: Column(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AI 正在生成助记…',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_mnemonic != null) ...[
              // 助记类型标签
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_mnemonic!.typeIcon} ${_mnemonic!.typeLabel}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.accentOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 助记内容
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.mintDeep.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.mintDeep.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  _mnemonic!.content,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: colors.ink,
                  ),
                ),
              ),

              // AI 例句
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.mintDeep.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: colors.mintDeep
                              .withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI 例句',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.mintDeep
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AiExampleSentences(
                      wordId: widget.wordId,
                      word: widget.word,
                      definition: _definition,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 无助记数据
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.sentiment_neutral_rounded,
                        size: 32, color: colors.inkSoft),
                    const SizedBox(height: 8),
                    Text(
                      _error ?? '该单词暂无AI助记',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: colors.inkSoft, fontSize: 14),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadData,
                        child: const Text('重新生成'),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        '配置 API Key 后可使用 AI 实时生成',
                        style: TextStyle(
                            color: colors.inkSoft, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('知道了'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 词根透视镜弹窗
class _RootLensDialog extends StatelessWidget {
  final String word;
  final RootBreakdown breakdown;

  const _RootLensDialog({
    required this.word,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Row(
              children: [
                Icon(Icons.visibility,
                    color: colors.mintDeep, size: 24),
                const SizedBox(width: 8),
                Text(
                  '词根透视镜',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.mintDeep,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 单词
            Text(
              word,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (breakdown.isValid) ...[
              // 词根拆解
              NeumorphicCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      breakdown.formatted,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: colors.mintDeep,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 拆解说明
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        if (breakdown.prefix.isNotEmpty)
                          _buildPartChip(
                            breakdown.prefix,
                            RootEngine.prefixes[breakdown.prefix] ?? '',
                            AppColors.accentOrange,
                          ),
                        if (breakdown.root.isNotEmpty)
                          _buildPartChip(
                            breakdown.root,
                            RootEngine.roots[breakdown.root] ?? '',
                            colors.mintDeep,
                          ),
                        if (breakdown.suffix.isNotEmpty)
                          _buildPartChip(
                            breakdown.suffix,
                            RootEngine.suffixes[breakdown.suffix] ?? '',
                            AppColors.success,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 含义组合
              Text(
                breakdown.meaning,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.inkSoft,
                ),
              ),
            ] else ...[
              // 无法拆解
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '该单词暂无词根拆解信息',
                  style: TextStyle(
                    color: colors.inkSoft,
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartChip(String part, String meaning, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: part,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: ' $meaning',
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
