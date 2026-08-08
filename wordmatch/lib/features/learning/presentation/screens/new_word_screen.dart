import 'package:flutter/material.dart';
import 'package:wordmatch/core/router/app_router.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/game/domain/services/root_engine.dart';
import 'package:wordmatch/features/learning/presentation/screens/dialogue_practice_screen.dart';
import 'package:wordmatch/features/learning/presentation/screens/word_network_screen.dart';
import 'package:wordmatch/features/learning/presentation/widgets/ai_example_sentences.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';
import 'package:wordmatch/shared/utils/audio_player.dart';
import 'package:wordmatch/shared/utils/haptic_util.dart';
import 'package:wordmatch/shared/widgets/speak_button.dart';

/// 设计规格强调色（品牌薄荷绿，浅/深色通用）
const _accent = Color(0xFF9FE870);
const _accentOn = Color(0xFF163300);
const _danger = Color(0xFFD03238);

/// 动画阶段
enum _AnimPhase { idle, slideOut, slideIn }

/// 新词卡片学习页面（匹配设计稿）
class NewWordScreen extends StatefulWidget {
  final List<Word> words;
  final VoidCallback onComplete;
  final void Function(List<bool> recognizedList)? onRecognitionComplete;

  /// 浏览模式：同反义词网络 chip 跳转时复用本页展示单词详情。
  /// true 时强制展开详情、隐藏进度点与认识/不认识按钮、标题改为「单词详情」。
  final bool browseMode;

  const NewWordScreen({
    super.key,
    required this.words,
    required this.onComplete,
    this.onRecognitionComplete,
    this.browseMode = false,
  });

  @override
  State<NewWordScreen> createState() => _NewWordScreenState();
}

class _NewWordScreenState extends State<NewWordScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final List<bool> _recognizedList = [];
  _AnimPhase _phase = _AnimPhase.idle;
  bool _isAnimating = false;

  /// 是否已展示释义等学习详情
  /// false：自测态，仅显示单词+音标
  /// true：学习态，显示完整信息
  bool _showDetails = false;

  // 两个独立的动画控制器，各自用合适的曲线和时长
  late final AnimationController _outController;
  late final AnimationController _inController;
  late final Animation<double> _outAnim;
  late final Animation<double> _inAnim;

  @override
  void initState() {
    super.initState();

    // 浏览模式直接展开详情，跳过自测态
    _showDetails = widget.browseMode;

    // 滑出：快出，easeOut 曲线
    _outController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _outAnim = CurvedAnimation(parent: _outController, curve: Curves.easeOut);

    // 滑入：自然减速，easeOutCubic 曲线
    _inController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _inAnim =
        CurvedAnimation(parent: _inController, curve: Curves.easeOutCubic);

    // 自动朗读第一个词（浏览模式不打扰，跳过）
    if (widget.words.isNotEmpty && !widget.browseMode) {
      Future.microtask(() => AudioPlayerUtil.speakWord(widget.words[0].word));
    }
  }

  @override
  void dispose() {
    _outController.dispose();
    _inController.dispose();
    super.dispose();
  }

  void _nextWord({required bool recognized}) {
    if (_isAnimating) return; // 防连点
    HapticUtil.buttonTap();
    _recognizedList.add(recognized);

    if (_currentIndex >= widget.words.length - 1) {
      // 学习完成
      widget.onRecognitionComplete?.call(_recognizedList);
      widget.onComplete();
      return;
    }

    _isAnimating = true;

    // 第一阶段：滑出
    setState(() => _phase = _AnimPhase.slideOut);
    _outController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      // 切换词
      setState(() {
        _currentIndex++;
        _phase = _AnimPhase.slideIn;
        // 浏览模式始终展开详情；学习模式切到下一词时回到自测态
        _showDetails = widget.browseMode;
      });
      // 自动朗读新词（浏览模式不打扰）
      if (!widget.browseMode) {
        AudioPlayerUtil.speakWord(widget.words[_currentIndex].word);
      }
      // 第二阶段：滑入
      _inController.forward(from: 0.0).then((_) {
        if (!mounted) return;
        setState(() {
          _phase = _AnimPhase.idle;
          _isAnimating = false;
        });
      });
    });
  }

  /// 处理"不认识"按钮
  ///
  /// 自测态：展示详情进入学习模式；
  /// 学习态：标记为未掌握并进入下一词。
  void _onUnknownPressed() {
    if (_isAnimating) return;
    if (_showDetails) {
      _nextWord(recognized: false);
    } else {
      HapticUtil.buttonTap();
      setState(() => _showDetails = true);
    }
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

  String _bookLabel(String bookId) {
    switch (bookId) {
      case 'gaokao':
        return '高考';
      case 'cet4':
        return '四级';
      case 'cet6':
        return '六级';
      case 'kaoyan':
        return '考研';
      case 'it':
        return 'IT';
      default:
        return '词库';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('无新词需要学习')),
      );
    }

    final word = widget.words[_currentIndex];
    final total = widget.words.length;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 导航栏
            _buildNavBar(total, colors),
            // 进度点（浏览模式隐藏）
            if (!widget.browseMode) _buildProgressDots(total, colors),
            // 卡片区域
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _buildAnimatedCard(word, colors),
              ),
            ),
            // 操作按钮（浏览模式隐藏）
            if (!widget.browseMode) _buildActions(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 导航栏：返回按钮 + 标题 + 进度计数
  Widget _buildNavBar(int total, AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          // 返回按钮
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _accentOn.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded,
                  size: 18, color: _accentOn),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                widget.browseMode ? '单词详情' : '新词学习',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: colors.ink,
                ),
              ),
            ),
          ),
          // 进度计数（浏览模式占位保持标题居中）
          Text(
            widget.browseMode ? '' : '${_currentIndex + 1}/$total',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.inkFaint,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  /// 进度点指示器
  Widget _buildProgressDots(int total, AppColorScheme colors) {
    final displayTotal = total.clamp(1, 15);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(displayTotal, (i) {
          final isDone = i < _currentIndex;
          final isCurrent = i == _currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: isCurrent ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isDone
                  ? _accent
                  : isCurrent
                      ? _accentOn
                      : colors.divider,
            ),
          );
        }),
      ),
    );
  }

  /// 带滑出/滑入动画的卡片
  Widget _buildAnimatedCard(Word word, AppColorScheme colors) {
    // idle 状态直接展示，无变换
    if (_phase == _AnimPhase.idle) {
      return _buildWordCard(word, colors);
    }

    // 滑出阶段
    if (_phase == _AnimPhase.slideOut) {
      return AnimatedBuilder(
        animation: _outAnim,
        builder: (context, child) {
          final t = _outAnim.value;
          return Transform.translate(
            offset: Offset(t * 300, 0),
            child: Transform.rotate(
              angle: t * 0.14,
              child: Opacity(opacity: (1.0 - t).clamp(0.0, 1.0), child: child),
            ),
          );
        },
        child: _buildWordCard(word, colors),
      );
    }

    // 滑入阶段
    return AnimatedBuilder(
      animation: _inAnim,
      builder: (context, child) {
        final t = _inAnim.value;
        return Transform.translate(
          offset: Offset((1.0 - t) * -300, 0),
          child: Transform.rotate(
            angle: (1.0 - t) * -0.14,
            child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
          ),
        );
      },
      child: _buildWordCard(word, colors),
    );
  }

  /// 单词卡片（单面，所有信息直接展示）
  Widget _buildWordCard(Word word, AppColorScheme colors) {
    final breakdown = RootEngine.analyze(word.word);
    final primaryPos =
        word.definition.isNotEmpty ? _extractPos(word.definition.first) : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
          child: Column(
            children: [
              // 顶部：词库标签（右上）+ 频次星级（左上）
              // 仅在展开学习详情后显示
              if (_showDetails)
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: _buildStars(word.frequency, colors),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          _bookLabel(word.bookId),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _accentOn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (_showDetails) const SizedBox(height: 20),

              // 英文单词（大号 display 字体）
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  word.word,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: colors.ink,
                    height: 0.85,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              // 音标 + 发音按钮
              if (word.phoneticUs != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      word.phoneticUs!,
                      style: TextStyle(
                        fontSize: 18,
                        color: colors.inkSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SpeakButton(
                      text: word.word,
                      color: _accentOn,
                      size: 28,
                      iconSize: 14,
                    ),
                  ],
                ),
              const SizedBox(height: 4),

              // 自测态提示
              if (!_showDetails) ...[
                const SizedBox(height: 24),
                Text(
                  '认识吗？不认识可查看释义',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.inkSoft.withValues(alpha: 0.7),
                  ),
                ),
              ],

              // 学习详情（展开时显示）
              AnimatedOpacity(
                opacity: _showDetails ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: _showDetails
                    ? _buildWordDetails(word, primaryPos, breakdown, colors)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 单词学习详情：词性、释义、例句、词根、AI 例句等
  Widget _buildWordDetails(
    Word word,
    String? primaryPos,
    RootBreakdown breakdown,
    AppColorScheme colors,
  ) {
    return Column(
      children: [
        // 分隔线
        Container(
          width: 48,
          height: 2,
          margin: const EdgeInsets.symmetric(vertical: 16),
          color: colors.divider,
        ),

        // 词性标签
        if (primaryPos != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _accentOn.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              primaryPos,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _accentOn,
              ),
            ),
          ),

        // 中文释义
        Text(
          word.definition.map(_stripPos).join('；'),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: colors.ink,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),

        // 例句
        if (word.exampleSentence != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.mintBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    word.exampleSentence!,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.inkSoft,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SpeakButton(
                  text: word.exampleSentence!,
                  color: _accentOn,
                  size: 32,
                  iconSize: 18,
                ),
              ],
            ),
          ),
        ],

        // 词根透视
        if (breakdown.isValid) ...[
          const SizedBox(height: 16),
          _buildRootSection(breakdown, colors),
        ],

        // AI 例句
        const SizedBox(height: 20),
        _buildAiExampleSection(word, colors),
      ],
    );
  }

  /// AI 例句区域
  Widget _buildAiExampleSection(Word word, AppColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accentOn.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentOn.withValues(alpha: 0.08)),
      ),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 16, color: _accentOn.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Text(
                    'AI 例句',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _accentOn.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AiExampleSentences(
                key: ValueKey(word.id),
                wordId: word.id,
                word: word.word,
                definition: word.definition,
              ),
              const SizedBox(height: 12),
              // AI 扩展功能入口
              Wrap(
                spacing: 8,
                children: [
                  _buildAiActionChip(
                    icon: Icons.account_tree_outlined,
                    label: '同反义词',
                    onTap: () => _openWordNetwork(word),
                  ),
                  _buildAiActionChip(
                    icon: Icons.record_voice_over_outlined,
                    label: '口语对话',
                    onTap: () => _openDialoguePractice(word),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  Widget _buildAiActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: _accentOn.withValues(alpha: 0.7)),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: _accentOn.withValues(alpha: 0.85),
        ),
      ),
      backgroundColor: _accentOn.withValues(alpha: 0.04),
      side: BorderSide(color: _accentOn.withValues(alpha: 0.1)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: onTap,
    );
  }

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

  /// 频次星级
  Widget _buildStars(int frequency, AppColorScheme colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isOn = index < frequency;
        return Text(
          '★',
          style: TextStyle(
            fontSize: 12,
            color: isOn ? _accentOn : colors.divider,
          ),
        );
      }),
    );
  }

  /// 词根透视区域
  Widget _buildRootSection(RootBreakdown breakdown, AppColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accentOn.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentOn.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Text(
            '词根透视',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _accentOn,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              if (breakdown.prefix.isNotEmpty)
                _buildRootChip(
                  '${breakdown.prefix}- ${RootEngine.prefixes[breakdown.prefix] ?? ''}',
                  RootChipType.prefix,
                ),
              if (breakdown.root.isNotEmpty)
                _buildRootChip(
                  '${breakdown.root} ${RootEngine.roots[breakdown.root] ?? ''}',
                  RootChipType.stem,
                ),
              if (breakdown.suffix.isNotEmpty)
                _buildRootChip(
                  '-${breakdown.suffix} ${RootEngine.suffixes[breakdown.suffix] ?? ''}',
                  RootChipType.suffix,
                ),
            ],
          ),
          if (breakdown.meaning.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              breakdown.meaning,
              style: TextStyle(fontSize: 12, color: colors.inkSoft),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRootChip(String text, RootChipType type) {
    final (bgColor, textColor, borderColor) = switch (type) {
      RootChipType.prefix => (
          const Color(0xFFD4883A).withValues(alpha: 0.1),
          const Color(0xFFD4883A),
          const Color(0xFFD4883A).withValues(alpha: 0.2),
        ),
      RootChipType.stem => (
          _accentOn.withValues(alpha: 0.08),
          _accentOn,
          _accentOn.withValues(alpha: 0.15),
        ),
      RootChipType.suffix => (
          const Color(0xFF054D28).withValues(alpha: 0.08),
          const Color(0xFF054D28),
          const Color(0xFF054D28).withValues(alpha: 0.15),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  /// 底部操作按钮
  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // 不认识按钮
          Expanded(
            child: SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: _isAnimating ? null : _onUnknownPressed,
                style: OutlinedButton.styleFrom(
                  backgroundColor: _danger.withValues(alpha: 0.08),
                  disabledBackgroundColor: _danger.withValues(alpha: 0.04),
                  side: BorderSide(
                    color: _isAnimating
                        ? _danger.withValues(alpha: 0.1)
                        : _danger.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _showDetails ? '😕 仍不认识' : '😕 不认识',
                  style: TextStyle(
                    color:
                        _isAnimating ? _danger.withValues(alpha: 0.4) : _danger,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 认识按钮
          Expanded(
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed:
                    _isAnimating ? null : () => _nextWord(recognized: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  disabledBackgroundColor: _accent.withValues(alpha: 0.5),
                  foregroundColor: _accentOn,
                  disabledForegroundColor: _accentOn.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  _showDetails ? '😊 已认识' : '😊 认识',
                  style: const TextStyle(
                    color: _accentOn,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 词根部件类型
enum RootChipType { prefix, stem, suffix }
