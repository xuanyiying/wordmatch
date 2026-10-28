import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/core/constants/app_colors.dart';
import 'package:wordmatch/core/router/app_router.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/ai/data/services/ai_learning_service.dart';
import 'package:wordmatch/features/game/data/repositories/game_provider.dart';
import 'package:wordmatch/features/learning/domain/services/sm2_service.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';
import 'package:wordmatch/features/wordbook/data/repositories/word_repository.dart';
import 'package:wordmatch/shared/utils/audio_player.dart';
import 'package:wordmatch/shared/utils/haptic_util.dart';

class WordChainStoryScreen extends ConsumerStatefulWidget {
  final WordChainStoryArgs args;

  const WordChainStoryScreen({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<WordChainStoryScreen> createState() =>
      _WordChainStoryScreenState();
}

class _WordChainStoryScreenState extends ConsumerState<WordChainStoryScreen> {
  WordChainStory? _story;
  bool _isLoading = true;
  bool _rewarded = false;

  final WordRepository _wordRepo = WordRepository();

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  Future<void> _loadStory() async {
    final story = await AiLearningService.generateWordChainStory(
      todaysWords: widget.args.todaysWords,
      bookName: widget.args.bookName,
    );
    if (mounted) {
      setState(() {
        _story = story;
        _isLoading = false;
      });
    }
  }

  Future<void> _onSegmentTap(StorySegment segment) async {
    if (!segment.isTarget || segment.targetWordId == null) return;
    HapticUtil.buttonTap();

    final wordId = segment.targetWordId!;
    final word = await _wordRepo.findById(wordId) ??
        _findWordInArgs(wordId);

    if (word == null && !mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _WordDetailSheet(
        word: word ?? Word(
          id: wordId,
          word: segment.text,
          definition: [],
          bookId: '',
        ),
      ),
    );
  }

  Word? _findWordInArgs(String wordId) {
    for (final w in widget.args.todaysWords) {
      if (w.id == wordId) return w;
    }
    return null;
  }

  Future<void> _onRewardTap() async {
    if (_rewarded) return;
    HapticUtil.levelComplete();

    final storage = ref.read(progressStorageProvider);

    final updated = <WordProgress>[];
    for (final word in widget.args.todaysWords) {
      var progress = storage.getProgress(word.id);
      progress ??= WordProgress.newWord(word.id, word.bookId);

      final baseQ = progress.lastQuality.clamp(2, 5);
      final newQ = (baseQ + 0.5).clamp(2.0, 5.0).round();
      updated.add(Sm2Service.updateProgress(progress, newQ));
    }
    // 一次性落盘，避免逐词写入反复序列化整份进度
    await storage.updateAllProgress(updated);

    setState(() => _rewarded = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已记住了这些词的语境！去消消乐里巩固一下吧 🎉'),
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _story == null
                      ? _buildEmptyState()
                      : _buildStoryBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 18),
      decoration: BoxDecoration(
        gradient: colors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded,
                  size: 18, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '今日词串烧 📖',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded,
                size: 64, color: colors.inkSoft),
            const SizedBox(height: 16),
            Text(
              '暂时没有生成故事',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请检查 AI 配置或稍后重试',
              style: TextStyle(
                fontSize: 13,
                color: colors.inkSoft,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadStory();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重新生成'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryBody() {
    final story = _story!;
    final colors = context.appColors;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            story.title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: colors.mintDeep,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            story.contentZh,
            style: TextStyle(
              fontSize: 13,
              color: colors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: colors.mintDeep.withValues(alpha: 0.08),
              ),
            ),
            child: _buildRichText(story.segments),
          ),
          const SizedBox(height: 20),
          _buildRewardButton(),
        ],
      ),
    );
  }

  Widget _buildRichText(List<StorySegment> segments) {
    final colors = context.appColors;
    return Wrap(
      spacing: 2,
      runSpacing: 8,
      children: segments.map((seg) {
        if (seg.isTarget) {
          return GestureDetector(
            onTap: () => _onSegmentTap(seg),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                seg.text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.mintDeep,
                  height: 1.8,
                ),
              ),
            ),
          );
        }
        return Text(
          seg.text,
          style: TextStyle(
            fontSize: 15,
            color: colors.ink,
            height: 1.8,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRewardButton() {
    final enabled = !_rewarded;
    final colors = context.appColors;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? colors.headerGradient : null,
          color: enabled ? null : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: colors.mintDeep.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton.icon(
          onPressed: enabled ? _onRewardTap : null,
          icon: Icon(Icons.celebration_rounded,
              size: 20, color: enabled ? Colors.white : Colors.grey[500]),
          label: Text(
            _rewarded ? '✓ 已领取奖励' : '读完了！奖励记忆分 +0.5',
            style: TextStyle(
              color: enabled ? Colors.white : Colors.grey[500],
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _WordDetailSheet extends StatelessWidget {
  final Word word;

  const _WordDetailSheet({required this.word});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: colors.mintDeep,
                      ),
                    ),
                    if (word.phoneticUs != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        word.phoneticUs!,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.inkSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticUtil.buttonTap();
                  AudioPlayerUtil.speakWord(word.word);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: colors.headerGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colors.mintDeep.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '释义',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          if (word.definition.isNotEmpty)
            ...word.definition.take(3).map(
                  (d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.ink,
                        height: 1.5,
                      ),
                    ),
                  ),
                )
          else
            Text(
              '暂无释义',
              style: TextStyle(
                fontSize: 14,
                color: colors.inkSoft,
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
