import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordmatch/core/constants/app_colors.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/router/app_router.dart' show AppRouter, NewWordArgs;
import 'package:wordmatch/features/game/data/repositories/game_provider.dart';
import 'package:wordmatch/features/game/presentation/screens/game_screen.dart';
import 'package:wordmatch/features/learning/data/models/wrong_word.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';
import 'package:wordmatch/shared/utils/haptic_util.dart';

/// 错词本页面
class WrongWordScreen extends ConsumerStatefulWidget {
  const WrongWordScreen({super.key});

  @override
  ConsumerState<WrongWordScreen> createState() => _WrongWordScreenState();
}

class _WrongWordScreenState extends ConsumerState<WrongWordScreen> {
  List<WrongWord> _wrongWords = [];
  bool _isLoading = true;
  Map<String, Word> _wordMap = {}; // wordId → Word 缓存

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = ref.read(progressStorageProvider);

    final wrongWords = storage.getWrongWords();

    // 加载相关词库数据，构建 wordMap
    final bookIds = wrongWords.map((w) => w.bookId).toSet();
    final repo = ref.read(wordbookRepositoryProvider);
    final map = <String, Word>{};
    for (final bookId in bookIds) {
      if (bookId.startsWith('custom_')) continue;
      if (bookId.startsWith('wrong_words_')) continue;
      if (bookId.startsWith('domain_')) continue;
      try {
        final words = await repo.loadBook(bookId);
        for (final w in words) {
          map[w.id] = w;
        }
      } catch (_) {}
    }

    setState(() {
      _wrongWords = wrongWords;
      _wordMap = map;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 渐变头部
            _buildHeader(context),
            // 内容区
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _wrongWords.isEmpty
                      ? _buildEmptyState()
                      : _buildWordList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 渐变头部
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEF4444), Color(0xFFF97316)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '错词本',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '共 ${_wrongWords.length} 个错词，加油攻克它们',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          if (_wrongWords.isNotEmpty)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _showClearConfirm,
                icon: const Icon(Icons.delete_sweep_outlined,
                    color: Colors.white, size: 20),
                tooltip: '清空',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
        ],
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无错词',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            '继续保持，你很棒！',
            style: TextStyle(fontSize: 14, color: colors.inkSoft),
          ),
        ],
      ),
    );
  }

  /// 错词列表
  Widget _buildWordList() {
    return Column(
      children: [
        // 重练按钮
        if (_wrongWords.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePaddingH, 16, AppSizes.pagePaddingH, 8),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: ElevatedButton.icon(
                  onPressed: _startWrongWordGame,
                  icon: const Icon(Icons.replay_rounded,
                      color: Colors.white, size: 22),
                  label: const Text(
                    '错题重练',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
        // 列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePaddingH, 8, AppSizes.pagePaddingH, 24),
            itemCount: _wrongWords.length,
            itemBuilder: (context, index) {
              final wrongWord = _wrongWords[index];
              final word = _wordMap[wrongWord.wordId];
              return _buildWrongWordCard(wrongWord, word);
            },
          ),
        ),
      ],
    );
  }

  /// 点击错词卡片：跳转到单词学习页面（仅一个单词），方便重新学习
  void _openWordDetail(WrongWord wrongWord, Word? word) {
    HapticUtil.buttonTap();
    final List<Word> words = [];
    if (word != null) {
      words.add(word);
    } else {
      // 没有加载到 Word 对象时，构造一个最小可用的占位 Word
      final split = wrongWord.wordId.split('_');
      final display = split.isNotEmpty ? split.first : wrongWord.wordId;
      words.add(Word(
        id: wrongWord.wordId,
        word: display,
        phoneticUs: '',
        definition: const ['释义暂不可用'],
        bookId: wrongWord.bookId,
      ));
    }

    Navigator.of(context).pushNamed(
      AppRouter.newWord,
      arguments: NewWordArgs(
        words: words,
        onComplete: () {
          Navigator.of(context).pop();
        },
        // 单独查看时不保存新的自评进度（已在错词本内有记录）
        onRecognitionComplete: (_) {},
      ),
    );
  }

  /// 错词卡片
  Widget _buildWrongWordCard(WrongWord wrongWord, Word? word) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openWordDetail(wrongWord, word),
          onLongPress: () => _showDeleteConfirm(wrongWord),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // 错误次数角标
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: wrongWord.wrongCount >= 3
                        ? AppColors.error.withValues(alpha: 0.12)
                        : AppColors.accentOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${wrongWord.wrongCount}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: wrongWord.wrongCount >= 3
                            ? AppColors.error
                            : AppColors.accentOrange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // 单词信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word?.word ?? wrongWord.wordId.split('_').first,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        word != null ? word.definition.join('；') : '释义加载中...',
                        style: TextStyle(
                            fontSize: 13, color: colors.inkSoft),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (wrongWord.wrongContexts.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '最近：${wrongWord.wrongContexts.last}',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                AppColors.accentOrange.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // 删除按钮
                IconButton(
                  onPressed: () => _showDeleteConfirm(wrongWord),
                  icon: Icon(Icons.close_rounded,
                      size: 18,
                      color: colors.inkSoft.withValues(alpha: 0.5)),
                  tooltip: '移除',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 启动错题重练
  void _startWrongWordGame() async {
    HapticUtil.buttonTap();

    // 通过仓库直接加载词库并等待完成（与学习页一致），
    // 避免同步读取 AsyncValue 时词库仍在加载中导致游戏永不启动
    List<Word> words;
    try {
      words = await ref
          .read(wordbookRepositoryProvider)
          .loadBook(ref.read(currentBookIdProvider))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => <Word>[],
          );
    } catch (_) {
      words = [];
    }

    // 词库加载失败时提示并中止，避免进入游戏页后停留在加载态
    if (words.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('词库加载失败，请稍后重试')),
      );
      return;
    }

    // 读取用户保存的配对数偏好
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final pairCount = prefs.getInt('pref_pair_count') ?? 8;

    ref
        .read(gameNotifierProvider.notifier)
        .startWrongWordGame(words, pairCount);

    if (!mounted) return;
    await Navigator.of(context).pushNamed(
      AppRouter.game,
      arguments: GameScreenArgs(
        pairCount: pairCount,
        bookId: ref.read(currentBookIdProvider),
      ),
    );

    // 返回后刷新数据
    _loadData();
  }

  /// 显示删除确认
  void _showDeleteConfirm(WrongWord wrongWord) {
    final word = _wordMap[wrongWord.wordId];
    final displayName = word?.word ?? wrongWord.wordId.split('_').first;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('移除错词？'),
        content: Text('确定要将「$displayName」从错词本中移除吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('移除'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        final storage = ref.read(progressStorageProvider);
        await storage.removeWrongWord(wrongWord.wordId);
        HapticUtil.matchSuccess();
        _loadData();
      }
    });
  }

  /// 显示清空确认
  void _showClearConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('清空错词本？'),
        content: const Text('确定要清空所有错词记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('清空'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        final storage = ref.read(progressStorageProvider);
        await storage.clearWrongWords();
        HapticUtil.matchSuccess();
        _loadData();
      }
    });
  }
}
