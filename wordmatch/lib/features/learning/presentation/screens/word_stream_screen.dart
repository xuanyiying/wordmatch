import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/core/constants/app_colors.dart';
import 'package:wordmatch/core/router/app_router.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/ai/data/services/ai_learning_service.dart';
import 'package:wordmatch/features/game/data/repositories/game_provider.dart';
import 'package:wordmatch/features/game/domain/services/root_engine.dart';
import 'package:wordmatch/features/learning/data/services/mnemonic_service.dart';
import 'package:wordmatch/features/learning/domain/services/sm2_service.dart';
import 'package:wordmatch/features/learning/presentation/screens/dialogue_practice_screen.dart';
import 'package:wordmatch/features/learning/presentation/screens/word_network_screen.dart';
import 'package:wordmatch/features/learning/presentation/widgets/ai_example_sentences.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';
import 'package:wordmatch/shared/utils/audio_player.dart';
import 'package:wordmatch/shared/utils/haptic_util.dart';
import 'package:wordmatch/shared/widgets/speak_button.dart';

class WordStreamScreen extends ConsumerStatefulWidget {
  final WordStreamArgs? args;

  const WordStreamScreen({
    super.key,
    this.args,
  });

  @override
  ConsumerState<WordStreamScreen> createState() => _WordStreamScreenState();
}

class _WordStreamScreenState extends ConsumerState<WordStreamScreen>
    with TickerProviderStateMixin {
  late List<Word> _words;
  int _currentIndex = 0;
  DateTime _cardShownAt = DateTime.now();
  final Set<String> _favIds = {};

  late final AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _words = widget.args?.words ?? [];
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _cardShownAt = DateTime.now();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  int _qualityForStay(Duration stay) {
    final ms = stay.inMilliseconds;
    if (ms < 1000) return 5;
    if (ms < 3000) return 3;
    return 1;
  }

  Future<void> _applyProgressFor(Word word, int q) async {
    final storage = ref.read(progressStorageProvider);
    await storage.init();
    var progress = storage.getProgress(word.id);
    progress ??= WordProgress.newWord(word.id, word.bookId);
    progress = Sm2Service.updateProgress(progress, q);
    await storage.updateProgress(progress);
  }

  Future<void> _addWrongWord(Word word) async {
    final storage = ref.read(progressStorageProvider);
    await storage.init();
    await storage.addWrongWord(
      wordId: word.id,
      bookId: word.bookId,
      context: '单词流下滑标记顽固',
    );
  }

  void _advance({
    required Offset direction,
    required VoidCallback onDone,
  }) {
    if (_words.isEmpty) return;
    HapticUtil.buttonTap();

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: direction,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _slideController.forward(from: 0).then((_) {
      onDone();
      if (!mounted) return;
      if (_currentIndex >= _words.length - 1) {
        _showCompletion();
      } else {
        setState(() {
          _currentIndex++;
          _cardShownAt = DateTime.now();
          _dragOffset = Offset.zero;
        });
        _slideController.reset();
      }
    });
  }

  void _onSwipeUp() {
    final stay = DateTime.now().difference(_cardShownAt);
    final q = _qualityForStay(stay);
    final word = _words[_currentIndex];
    _applyProgressFor(word, q);
    _advance(
      direction: const Offset(0, -1.5),
      onDone: () {},
    );
  }

  void _onSwipeDown() {
    final word = _words[_currentIndex];
    _applyProgressFor(word, 1);
    _addWrongWord(word);
    _advance(
      direction: const Offset(0, 1.5),
      onDone: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('「${word.word}」已标记为顽固词，加入错词本'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }

  void _onSwipeLeft() {
    final word = _words[_currentIndex];
    setState(() {
      _favIds.add(word.id);
    });
    _advance(
      direction: const Offset(-1.5, 0),
      onDone: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⭐ 已收藏「${word.word}」'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }

  void _showCompletion() {
    final colors = context.appColors;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: AppColors.accentOrange),
            SizedBox(width: 8),
            Text('完成啦！'),
          ],
        ),
        content: Text(
          '已经刷完 ${_words.length} 个词了，休息一下吧 🌿',
          style: TextStyle(color: colors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('返回首页'),
          ),
          if (_words.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _currentIndex = 0;
                  _cardShownAt = DateTime.now();
                });
                _slideController.reset();
              },
              child: const Text('再来一遍'),
            ),
        ],
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _isDragging = true;
      _dragOffset += d.delta;
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_isDragging) return;
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;

    setState(() {
      _isDragging = false;
      _dragOffset = Offset.zero;
    });

    if (dy < -50 && dy.abs() > dx.abs()) {
      _onSwipeUp();
    } else if (dy > 50 && dy.abs() > dx.abs()) {
      _onSwipeDown();
    } else if (dx < -50) {
      _onSwipeLeft();
    }
  }

  void _showRootSheet(Word word) {
    final breakdown = RootEngine.analyze(word.word);
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 20, color: colors.mintDeep),
                const SizedBox(width: 8),
                Text(
                  '词根拆解',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.mintDeep,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (breakdown.isValid) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (breakdown.prefix.isNotEmpty)
                    _rootChip(
                      '${breakdown.prefix}- ${RootEngine.prefixes[breakdown.prefix] ?? ''}',
                      const Color(0xFFD4883A),
                    ),
                  if (breakdown.root.isNotEmpty)
                    _rootChip(
                      '${breakdown.root} ${RootEngine.roots[breakdown.root] ?? ''}',
                      colors.mintDeep,
                    ),
                  if (breakdown.suffix.isNotEmpty)
                    _rootChip(
                      '-${breakdown.suffix} ${RootEngine.suffixes[breakdown.suffix] ?? ''}',
                      const Color(0xFF054D28),
                    ),
                ],
              ),
              if (breakdown.meaning.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  breakdown.meaning,
                  style: TextStyle(fontSize: 14, color: colors.inkSoft),
                ),
              ],
            ] else
              Text(
                '暂未收录该词的词根拆解',
                style: TextStyle(fontSize: 14, color: colors.inkSoft),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _rootChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: _words.isEmpty ? _buildEmpty() : _buildStream(),
      ),
    );
  }

  Widget _buildEmpty() {
    final colors = context.appColors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.mintDeep.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back_rounded,
                      size: 18, color: colors.mintDeep),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '摸鱼刷词',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 38),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.coffee_rounded,
                      size: 72, color: colors.inkFaint),
                  const SizedBox(height: 18),
                  Text(
                    '暂无待刷的词',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '先去认识新朋友吧～',
                    style: TextStyle(fontSize: 14, color: colors.inkSoft),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('返回首页'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.mintDeep,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStream() {
    final word = _words[_currentIndex];
    final total = _words.length;
    final progress = total > 0 ? (_currentIndex + 1) / total : 0.0;
    final breakdown = RootEngine.analyze(word.word);

    return Column(
      children: [
        _buildTopBar(total, progress),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: AnimatedBuilder(
                animation: _slideController,
                builder: (ctx, _) {
                  final animOffset = _slideAnimation.value;
                  final dragOffset = _isDragging
                      ? _dragOffset.scale(1 / 400, 1 / 800)
                      : Offset.zero;
                  final totalOffset = Offset(
                        animOffset.dx + dragOffset.dx,
                        animOffset.dy + dragOffset.dy,
                      );
                  return Transform.translate(
                    offset: Offset(totalOffset.dx * 300, totalOffset.dy * 400),
                    child: Transform.rotate(
                      angle: totalOffset.dx * 0.08,
                      child: _buildCard(word, breakdown),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(int total, double progress) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.mintDeep.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back_rounded,
                  size: 18, color: colors.mintDeep),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor:
                        colors.mintDeep.withValues(alpha: 0.08),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colors.mintDeep),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currentIndex + 1} / $total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.inkSoft,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: Text(
              widget.args?.mode == 'review' ? '复习' : '今日',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.mintDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 从释义字符串提取词性标签（如 "v. 预言" → "v."）
  String? _extractPos(String definition) {
    final match = RegExp(r'^([a-z]+\.)\s').firstMatch(definition);
    return match?.group(1);
  }

  /// 从释义字符串去掉词性前缀
  String _stripPos(String definition) {
    return definition.replaceFirst(RegExp(r'^[a-z]+\.\s'), '');
  }

  /// 跳转同反义词网络
  void _openWordNetwork(Word word) {
    HapticUtil.buttonTap();
    Navigator.of(context).pushNamed(
      AppRouter.wordNetwork,
      arguments: WordNetworkArgs(
        wordId: word.id,
        word: word.word,
        definition: word.definition,
      ),
    );
  }

  /// 跳转口语对话练习
  void _openDialoguePractice(Word word) {
    HapticUtil.buttonTap();
    Navigator.of(context).pushNamed(
      AppRouter.dialoguePractice,
      arguments: DialoguePracticeArgs(
        wordId: word.id,
        word: word.word,
        definition: word.definition,
      ),
    );
  }

  Widget _buildCard(Word word, RootBreakdown breakdown) {
    final colors = context.appColors;
    final isFav = _favIds.contains(word.id);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.card,
            colors.mintDeep.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: colors.mintDeep.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
        border: Border.all(
          color: colors.mintDeep.withValues(alpha: 0.10),
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 72),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      word.word,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: colors.ink,
                        height: 0.9,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 音标 + 行内发音按钮
                  if (word.phoneticUs != null && word.phoneticUs!.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        HapticUtil.buttonTap();
                        AudioPlayerUtil.speakWord(word.word);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            word.phoneticUs!,
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.inkSoft,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.volume_up_rounded,
                              size: 16, color: colors.mintDeep),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  Container(
                    width: 48,
                    height: 2,
                    color: colors.mintDeep.withValues(alpha: 0.14),
                  ),
                  const SizedBox(height: 14),
                  // 全部释义（带词性标签）
                  ...word.definition.map(
                        (d) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              if (_extractPos(d) != null) ...[
                                Text(
                                  _extractPos(d)!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: colors.mintDeep,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  _stripPos(d),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: colors.ink,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  // 例句
                  if (word.exampleSentence != null &&
                      word.exampleSentence!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: colors.mintDeep.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.mintDeep.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.format_quote_rounded,
                              size: 14, color: colors.mintDeep),
                          const SizedBox(width: 6),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticUtil.buttonTap();
                                AudioPlayerUtil.speakWord(
                                    word.exampleSentence!);
                              },
                              child: Text(
                                word.exampleSentence!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.ink,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SpeakButton(
                            text: word.exampleSentence!,
                            color: colors.mintDeep,
                            size: 32,
                            iconSize: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                  // 词根拆解
                  if (breakdown.isValid) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (breakdown.prefix.isNotEmpty)
                          _miniRootChip(
                            '${breakdown.prefix}-',
                            const Color(0xFFD4883A),
                          ),
                        if (breakdown.root.isNotEmpty)
                          _miniRootChip(
                            breakdown.root,
                            colors.mintDeep,
                          ),
                        if (breakdown.suffix.isNotEmpty)
                          _miniRootChip(
                            '-${breakdown.suffix}',
                            const Color(0xFF054D28),
                          ),
                      ],
                    ),
                  ],
                  // AI 助记
                  const SizedBox(height: 16),
                  _buildMnemonicSection(word),
                  // AI 例句
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.mintDeep.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: colors.mintDeep.withValues(alpha: 0.10)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 15,
                                color: colors.mintDeep.withValues(alpha: 0.8)),
                            const SizedBox(width: 6),
                            Text('AI 例句',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colors.mintDeep)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AiExampleSentences(
                          key: ValueKey(word.id),
                          wordId: word.id,
                          word: word.word,
                          definition: word.definition,
                        ),
                      ],
                    ),
                  ),
                  // 词网络入口
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _actionChip(
                        icon: Icons.account_tree_outlined,
                        label: '同反义词',
                        onTap: () => _openWordNetwork(word),
                      ),
                      _actionChip(
                        icon: Icons.record_voice_over_outlined,
                        label: '口语对话',
                        onTap: () => _openDialoguePractice(word),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _floatBtn(
                  icon: Icons.lightbulb_outline,
                  onTap: () {
                    HapticUtil.buttonTap();
                    _showRootSheet(word);
                  },
                ),
                const SizedBox(width: 8),
                _floatBtn(
                  icon: isFav ? Icons.favorite_rounded : Icons.favorite_border,
                  color: isFav ? AppColors.error : null,
                  onTap: () {
                    HapticUtil.buttonTap();
                    setState(() {
                      if (isFav) {
                        _favIds.remove(word.id);
                      } else {
                        _favIds.add(word.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('⭐ 已收藏「${word.word}」'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// AI 助记区：异步加载，loading 显示骨架，命中显示内容
  Widget _buildMnemonicSection(Word word) {
    final colors = context.appColors;
    return FutureBuilder<Mnemonic?>(
      key: ValueKey('mnemonic_${word.id}'),
      future: AiLearningService.generateMnemonic(word.id, word.definition),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.mintDeep.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.mintDeep.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 10),
                Text('AI 助记生成中…',
                    style: TextStyle(
                        fontSize: 12, color: colors.inkSoft)),
              ],
            ),
          );
        }
        final m = snap.data;
        if (m == null || m.content.isEmpty) {
          return const SizedBox.shrink();
        }
        final typeLabel = switch (m.type) {
          'story' => '故事记忆',
          'homophone' => '谐音记忆',
          'association' => '联想记忆',
          _ => '助记',
        };
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.mintDeep.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: colors.mintDeep.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology_alt_rounded,
                      size: 15, color: colors.mintDeep),
                  const SizedBox(width: 6),
                  Text(typeLabel,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.mintDeep)),
                ],
              ),
              const SizedBox(height: 6),
              Text(m.content,
                  style: TextStyle(
                      fontSize: 13, height: 1.6, color: colors.ink)),
            ],
          ),
        );
      },
    );
  }

  /// 底部动作 chip（同反义词 / 口语对话入口）
  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: colors.mintDeep),
      label: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: colors.mintDeep,
              fontWeight: FontWeight.w600)),
      backgroundColor: colors.mintDeep.withValues(alpha: 0.06),
      side: BorderSide(color: colors.mintDeep.withValues(alpha: 0.18)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      onPressed: onTap,
    );
  }

  Widget _miniRootChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _floatBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final colors = context.appColors;
    final c = color ?? colors.mintDeep;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: c.withValues(alpha: 0.12),
          ),
        ),
        child: Icon(icon, color: c, size: 20),
      ),
    );
  }

}
