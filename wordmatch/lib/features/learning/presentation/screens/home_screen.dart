import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordmatch/core/constants/app_colors.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/constants/app_strings.dart';
import 'package:wordmatch/core/router/app_router.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/game/data/repositories/game_provider.dart';
import 'package:wordmatch/features/game/presentation/screens/game_screen.dart';
import 'package:wordmatch/features/learning/domain/services/plan_service.dart';
import 'package:wordmatch/features/learning/domain/services/sm2_service.dart';
import 'package:wordmatch/features/wordbook/data/datasources/local_word_datasource.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';
import 'package:wordmatch/shared/utils/haptic_util.dart';
import 'package:wordmatch/shared/widgets/app_logo.dart';
import 'package:wordmatch/shared/widgets/gradient_page_header.dart';

/// 学习 Tab（底部导航「学习」页内容）
class LearnTab extends ConsumerStatefulWidget {
  const LearnTab({super.key});

  @override
  ConsumerState<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends ConsumerState<LearnTab> {
  LearningPlan? _currentPlan;
  DailyTask? _dailyTask;
  DailyTaskState? _taskState;
  bool _isLoading = true;
  int _masteredCount = 0;
  int _learnedCount = 0;
  List<BookInfo> _books = const [];
  int? _userDailyNewWords;
  int _pairCount = 8; // 每局配对数

  static const _pairCountOptions = [4, 8, 12, 18];
  static const _pairCountPrefsKey = 'pref_pair_count';

  @override
  void initState() {
    super.initState();
    _initPlan();
    _loadPairCount();
  }

  Future<void> _loadPairCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _pairCount = prefs.getInt(_pairCountPrefsKey) ?? 8;
      });
    }
  }

  Future<void> _savePairCount(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pairCountPrefsKey, value);
  }

  Future<void> _initPlan() async {
    try {
      // 初始化进度存储
      final storage = ref.read(progressStorageProvider);
      await storage.init();
      _masteredCount = storage.getMasteredCount();
      _learnedCount = storage.getLearnedCount();

      _books = await ref.read(wordbookRepositoryProvider).getAvailableBooks();

      // 加载今日任务状态
      _taskState = storage.getDailyTaskState();
      // 校验 bookId 一致性
      if (_taskState != null &&
          _taskState!.bookId != ref.read(currentBookIdProvider)) {
        _taskState = null;
        await storage.clearDailyTaskState();
      }

      // 加载用户保存的每日新词设置
      final planSettings = storage.getPlanSettings();
      _userDailyNewWords = planSettings?['dailyNewWords'] as int?;

      // 直接通过仓库加载词库（绕过 wordListProvider，避免 Riverpod 状态卡死）
      final bookId = ref.read(currentBookIdProvider);
      final repo = ref.read(wordbookRepositoryProvider);
      final words = await repo.loadBook(bookId).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[_initPlan] 词库加载超时!');
          return <Word>[];
        },
      );

      if (words.isNotEmpty) {
        final allProgress = storage.getAllProgress();

        final plan = PlanService.generatePlan(
          bookId: bookId,
          examDate: DateTime.now().add(const Duration(days: 90)),
          dailyMinutes: 30,
          totalWords: words.length,
          masteredWords: _masteredCount,
          allProgress: allProgress,
          dailyNewWordsOverride: _userDailyNewWords,
        );
        final task = PlanService.generateDailyTask(
          plan: plan,
          allWords: words,
          allProgress: allProgress,
          existingTaskState: _taskState,
        );
        if (mounted) {
          setState(() {
            _currentPlan = plan;
            _dailyTask = task;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e, st) {
      debugPrint('[_initPlan] 初始化失败: $e');
      debugPrint('[_initPlan] 堆栈: $st');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // 渐变头部（固定顶部，统一规格）
                  _buildHeader(context),
                  const SizedBox(height: 12),

                  // 内容区（自适应剩余高度，超长时内部滚动）
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _initPlan,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.pagePaddingH,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 词库选择面板（标签快切 + 自定义导入）
                              _buildBookTagPanel(context),
                              const SizedBox(height: 10),

                              // 整合卡：进度统计 + 今日任务（合并为一张绿色渐变卡）
                              _buildUnifiedCard(context),
                              const SizedBox(height: 12),

                              // 每局配对数选择
                              _buildPairCountSelector(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 底部固定操作区（SafeArea 底部，保证不被 Home 指示条遮挡）
                  _buildBottomActions(context),
                ],
              ),
      ),
    );
  }

  /// 底部固定操作区：主按钮 + 次要按钮，固定在底部并避开 Home 指示条。
  Widget _buildBottomActions(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSizes.pagePaddingH,
        4,
        AppSizes.pagePaddingH,
        8,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 主按钮（根据任务状态切换，标签与图标对齐设计稿）
            if (_dailyTask?.canAdvancePlan == true)
              _buildGradientButton(
                onPressed: () {
                  HapticUtil.buttonTap();
                  _advanceToNextPlan();
                },
                icon: Icons.arrow_forward_rounded,
                label: '进入下一计划 →',
              )
            else if (_dailyTask?.canPlayGame == true)
              _buildGradientButton(
                onPressed: () {
                  HapticUtil.buttonTap();
                  _startNewWordGame();
                },
                icon: Icons.sports_esports_rounded,
                label: '开始消消乐 →',
              )
            else if (_dailyTask != null &&
                _dailyTask!.newWords.isNotEmpty &&
                !(_dailyTask?.hasLearnedToday ?? false))
              _buildGradientButton(
                onPressed: () {
                  HapticUtil.buttonTap();
                  _startNewWordLearning(context);
                },
                icon: Icons.auto_stories_rounded,
                label:
                    '开始学习 (${_dailyTask?.newWordsTarget ?? 0}词) →',
              )
            else if (_dailyTask != null &&
                _dailyTask!.reviewWords.isNotEmpty)
              _buildGradientButton(
                onPressed: () {
                  HapticUtil.buttonTap();
                  _startReview(context);
                },
                icon: Icons.refresh_rounded,
                label: '开始复习 →',
              )
            else
              _buildGradientButton(
                onPressed: null,
                icon: Icons.check_circle_rounded,
                label: '今日任务已完成 ✓',
              ),

            // 次要按钮（词串烧 + 摸鱼刷词），可横向并排节省纵向空间
            if ((_dailyTask?.newWords.isNotEmpty == true) ||
                (_dailyTask?.reviewWords.isNotEmpty == true)) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_dailyTask?.newWords.isNotEmpty == true) ...[
                    Expanded(
                      child: _buildGhostButton(
                        onPressed: () {
                          HapticUtil.buttonTap();
                          Navigator.of(context).pushNamed(
                            AppRouter.wordChainStory,
                            arguments: WordChainStoryArgs(
                              todaysWords: _dailyTask!.newWords,
                              bookName: _bookName(
                                  ref.read(currentBookIdProvider)),
                            ),
                          );
                        },
                        icon: Icons.menu_book_rounded,
                        label:
                            '词串烧 (${_dailyTask!.newWords.length}词)',
                      ),
                    ),
                  ],
                  if ((_dailyTask?.reviewWords.isNotEmpty == true) ||
                      (_dailyTask?.newWords.isNotEmpty == true)) ...[
                    if (_dailyTask?.newWords.isNotEmpty == true)
                      const SizedBox(width: 8),
                    Expanded(
                      child: _buildGhostButton(
                        onPressed: () {
                          HapticUtil.buttonTap();
                          final words = [
                            ...?_dailyTask?.reviewWords,
                            ...?_dailyTask?.newWords,
                          ];
                          Navigator.of(context).pushNamed(
                            AppRouter.wordStream,
                            arguments: WordStreamArgs(
                              words: words,
                              mode: 'today',
                            ),
                          );
                        },
                        icon: Icons.swipe_rounded,
                        label: '摸鱼刷词 (${[
                          ...?_dailyTask?.reviewWords,
                          ...?_dailyTask?.newWords,
                        ].length}词)',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 渐变头部区域（统一规格，与各子页面 header 一致）
  Widget _buildHeader(BuildContext context) {
    return const GradientPageHeader(
      title: AppStrings.appName,
      subtitle: '玩着玩着，单词就记住了',
      showBackButton: false,
      leading: AppLogoStatic(size: 40),
    );
  }

  /// 词库选择面板：标签快切 + 自定义导入入口
  Widget _buildBookTagPanel(BuildContext context) {
    final colors = context.appColors;
    final currentBookId = ref.read(currentBookIdProvider);
    final currentBook = _books.firstWhere(
      (b) => b.id == currentBookId,
      orElse: () => const BookInfo(
          id: '', name: '', wordCount: 0, available: true),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Row(
          children: [
            Icon(Icons.library_books_outlined,
                size: 14, color: colors.ink),
            const SizedBox(width: 5),
            Text('词库',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.ink)),
            const Spacer(),
            if (currentBook.id.isNotEmpty)
              Text(
                '${currentBook.name} · ${currentBook.wordCount}词',
                style: TextStyle(
                    fontSize: 11,
                    color: colors.inkSoft,
                    fontWeight: FontWeight.w500),
              ),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final book in _books)
              _buildBookTag(book, selected: book.id == currentBookId),
            _buildAddCustomTag(),
          ],
        ),
      ],
    );
  }

  /// 单个词库标签
  Widget _buildBookTag(BookInfo book, {required bool selected}) {
    final colors = context.appColors;
    final dotColor = _bookTagColor(book.id);
    return InkWell(
      onTap: () {
        HapticUtil.buttonTap();
        if (book.id != ref.read(currentBookIdProvider)) {
          ref.read(currentBookIdProvider.notifier).setBookId(book.id);
          _initPlan();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [colors.mintLight, colors.mintDeep],
                )
              : null,
          color: selected ? null : colors.card,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? null
              : Border.all(color: colors.border, width: 1.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.mintDeep.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(_bookShortName(book),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? colors.ink : colors.inkSoft,
                )),
            const SizedBox(width: 4),
            Text('${book.wordCount}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? colors.ink.withValues(alpha: 0.7)
                      : colors.inkFaint,
                )),
          ],
        ),
      ),
    );
  }

  /// 「自定义」导入入口标签
  Widget _buildAddCustomTag() {
    final colors = context.appColors;
    return InkWell(
      onTap: () async {
        HapticUtil.buttonTap();
        final result =
            await Navigator.of(context).pushNamed(AppRouter.importWordbook);
        if (result == true) _initPlan();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: colors.amberBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.amber, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 14, color: colors.amber),
            const SizedBox(width: 3),
            Text('自定义',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.amber)),
          ],
        ),
      ),
    );
  }

  String _bookName(String bookId) {
    switch (bookId) {
      case 'gaokao':
        return '高考词汇';
      case 'cet4':
        return '四级词汇';
      case 'cet6':
        return '六级词汇';
      case 'kaoyan':
        return '考研词汇';
      case 'it':
        return 'IT技术词汇';
      default:
        return '自定义词库';
    }
  }

  /// 标签短名（用于标签展示）
  String _bookShortName(BookInfo book) {
    if (book.isCustom) return book.name;
    switch (book.id) {
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
        return book.name;
    }
  }

  /// 标签圆点配色（年轻化辅助色）
  Color _bookTagColor(String bookId) {
    final colors = context.appColors;
    switch (bookId) {
      case 'gaokao':
        return colors.mintDeep;
      case 'cet4':
        return AppColors.sky;
      case 'cet6':
        return AppColors.lilac;
      case 'kaoyan':
        return AppColors.coral;
      case 'it':
        return colors.inkSoft;
      default:
        return colors.amber;
    }
  }

  /// 整合卡：今日计划（进度统计 + 任务入口，合并为一张绿色渐变卡）
  Widget _buildUnifiedCard(BuildContext context) {
    final learnedDone = _dailyTask?.hasLearnedToday == true;
    final reviewDone = _dailyTask?.hasPlayedGameToday == true;
    final newTarget = _dailyTask?.newWordsTarget ?? 0;
    final reviewTarget = _dailyTask?.reviewWordsTarget ?? 0;
    final dueReview = _currentPlan?.reviewDebt ?? 0;
    final newLearned = _taskState?.learnedWordIds.length ?? 0;

    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        gradient: colors.headerGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.mintDeep.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 装饰光晕
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.mintLight.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部：sparkle 图标 + 标题 + 调整按钮
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Icon(Icons.auto_awesome,
                          size: 15, color: colors.mintLight),
                    ),
                    const SizedBox(width: 8),
                    const Text('今日计划',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        HapticUtil.buttonTap();
                        _showPlanSettings();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(Icons.tune_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 3 个进度统计（玻璃拟态）
                Row(
                  children: [
                    Expanded(
                        child:
                            _buildUcStat('$_learnedCount', '已学习', false)),
                    const SizedBox(width: 6),
                    Expanded(
                        child:
                            _buildUcStat('$_masteredCount', '已掌握', true)),
                    const SizedBox(width: 6),
                    Expanded(
                        child: _buildUcStat('$dueReview', '待复习', false)),
                  ],
                ),
                // 渐变分隔线
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // 2 个任务卡（并排，可点击）
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildUcTask(
                        icon: Icons.add_rounded,
                        num: newTarget,
                        label: '今日新词',
                        cta: learnedDone
                            ? '已完成 $newTarget/$newTarget ✓'
                            : (newLearned > 0
                                ? '继续学习 $newLearned/$newTarget →'
                                : '开始学习 →'),
                        isPrimary: !learnedDone,
                        onTap: learnedDone
                            ? null
                            : () {
                                HapticUtil.buttonTap();
                                if (_dailyTask?.canAdvancePlan == true) {
                                  _advanceToNextPlan();
                                } else {
                                  _startNewWordLearning(context);
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildUcTask(
                        icon: Icons.refresh_rounded,
                        num: reviewTarget,
                        label: '今日复习',
                        cta: reviewDone
                            ? '已完成 ✓'
                            : (reviewTarget > 0 ? '开始复习 →' : '今日无需复习'),
                        isPrimary: false,
                        onTap: (reviewTarget > 0 && !reviewDone)
                            ? () {
                                HapticUtil.buttonTap();
                                _startReview(context);
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 整合卡：单个进度统计（玻璃拟态）
  Widget _buildUcStat(String num, String label, bool isMaster) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: isMaster
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.mintLight.withValues(alpha: 0.28),
                  colors.mintLight.withValues(alpha: 0.12),
                ],
              )
            : null,
        color: isMaster ? null : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMaster
              ? colors.mintLight.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Text(num,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                  letterSpacing: -0.5)),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// 整合卡：单个任务卡（可点击）
  Widget _buildUcTask({
    required IconData icon,
    required int num,
    required String label,
    required String cta,
    required bool isPrimary,
    required VoidCallback? onTap,
  }) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.mintLight.withValues(alpha: 0.3),
                    colors.mintLight.withValues(alpha: 0.14),
                  ],
                )
              : null,
          color: isPrimary ? null : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary
                ? colors.mintLight.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                gradient: isPrimary
                    ? LinearGradient(
                        colors: [colors.mintLight, colors.mintDeep],
                      )
                    : null,
                color: isPrimary ? null : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: isPrimary
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Icon(icon,
                  size: 15, color: isPrimary ? colors.ink : Colors.white),
            ),
            const SizedBox(height: 8),
            Text('$num',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: -0.8)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(cta,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isPrimary
                        ? const Color(0xFFC8F0B8)
                        : Colors.white.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  /// 每局配对数选择器（自定义芯片行，对齐设计稿）
  Widget _buildPairCountSelector() {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.view_module_rounded,
                size: 14, color: colors.mintDeep),
            const SizedBox(width: 5),
            Text('每局词数',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.ink)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(_pairCountOptions.length, (idx) {
            final count = _pairCountOptions[idx];
            final selected = count == _pairCount;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: idx == 0 ? 0 : 3,
                  right: idx == _pairCountOptions.length - 1 ? 0 : 3,
                ),
                child: GestureDetector(
                  onTap: () {
                    HapticUtil.buttonTap();
                    setState(() => _pairCount = count);
                    _savePairCount(count);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [colors.mintLight, colors.mintDeep],
                            )
                          : null,
                      color: selected ? null : colors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? null
                          : Border.all(color: colors.border, width: 1.5),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: colors.mintDeep
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Text('$count对',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? colors.ink : colors.inkSoft,
                        )),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// 渐变主按钮（对齐设计稿：54 高 · 17 圆角 · 三色渐变）
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
  }) {
    final colors = context.appColors;
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? colors.headerGradient : null,
          color: enabled ? null : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: colors.mintDeep.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon,
              size: 20, color: enabled ? Colors.white : Colors.grey[500]),
          label: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.grey[500],
              fontSize: 16,
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

  /// 次要 ghost 按钮（描边风格，用于词串烧等次要操作）
  Widget _buildGhostButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    final colors = context.appColors;
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: colors.mintDeep),
        label: Text(
          label,
          style: TextStyle(
            color: colors.mintDeep,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.mintBg,
          side: BorderSide(
              color: colors.mintDeep.withValues(alpha: 0.3), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _startNewWordLearning(BuildContext context) {
    if (_dailyTask == null) return;
    Navigator.of(context).pushNamed(
      AppRouter.newWord,
      arguments: NewWordArgs(
        words: _dailyTask!.newWords,
        onComplete: () {
          // 新词学完后标记学习完成
          Navigator.of(context).pop();
          _markLearningCompleted();
        },
        onRecognitionComplete: (recognizedList) {
          // 根据用户自评保存初始 SM-2 进度
          _saveNewWordRecognition(recognizedList);
        },
      ),
    );
  }

  /// 标记新词学习完成
  Future<void> _markLearningCompleted() async {
    if (_dailyTask == null) return;
    final storage = ref.read(progressStorageProvider);
    final wordIds = _dailyTask!.newWords.map((w) => w.id).toList();

    _taskState = DailyTaskState(
      bookId: ref.read(currentBookIdProvider),
      date: DateTime.now(),
      learningCompleted: true,
      learnedWordIds: wordIds,
    );
    await storage.saveDailyTaskState(_taskState!);

    setState(() {
      _dailyTask = _dailyTask?.copyWith(taskState: _taskState);
    });
  }

  /// 学完新词后的消消乐（使用今日刚学的新词）
  Future<void> _startNewWordGame() async {
    if (_dailyTask == null || _taskState == null) return;
    final wordIds = _taskState!.learnedWordIds.toSet();
    await Navigator.of(context).pushNamed(
      AppRouter.game,
      arguments: GameScreenArgs(
        pairCount: _pairCount,
        bookId: ref.read(currentBookIdProvider),
        newWordIds: wordIds,
        markDailyGameCompleted: true,
      ),
    );
    // 游戏返回后刷新状态
    _initPlan();
  }

  /// 根据新词学习的自评结果保存初始 SM-2 进度
  Future<void> _saveNewWordRecognition(List<bool> recognizedList) async {
    if (_dailyTask == null) return;
    final storage = ref.read(progressStorageProvider);
    await storage.init();
    final bookId = ref.read(currentBookIdProvider);

    final learnedCount =
        recognizedList.length > _dailyTask!.newWords.length
            ? _dailyTask!.newWords.length
            : recognizedList.length;

    for (var i = 0; i < learnedCount; i++) {
      final word = _dailyTask!.newWords[i];
      final recognized = recognizedList[i];
      var progress = storage.getProgress(word.id);
      progress ??= WordProgress.newWord(word.id, bookId);

      // "认识"→ Q=4（初步了解但还需巩固），"不认识"→ Q=0（完全陌生）
      final quality = recognized ? 4 : 0;
      progress = Sm2Service.updateProgress(progress, quality);
      await storage.updateProgress(progress);
    }

    // 记录今日新词学习量（每个新词约 0.7 分钟）
    if (learnedCount > 0) {
      await storage.recordDailyActivity(
        newWords: learnedCount,
        minutes: (learnedCount * 0.7).round(),
      );
    }
  }

  void _startReview(BuildContext context) {
    if (_dailyTask == null || _dailyTask!.reviewWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今日无需复习，明天再来吧！')),
      );
      return;
    }
    final reviewWordIds = _dailyTask!.reviewWords.map((w) => w.id).toSet();
    Navigator.of(context)
        .pushNamed(
          AppRouter.game,
          arguments: GameScreenArgs(
            pairCount: _pairCount,
            bookId: ref.read(currentBookIdProvider),
            reviewWordIds: reviewWordIds,
          ),
        )
        .then((_) => _initPlan());
  }

  /// 推进到下一个学习计划
  Future<void> _advanceToNextPlan() async {
    final storage = ref.read(progressStorageProvider);
    await storage.clearDailyTaskState();
    _taskState = null;
    await _initPlan();
    HapticUtil.levelComplete();
  }

  /// 显示计划设置弹窗
  void _showPlanSettings() {
    final currentNewWords = _currentPlan?.dailyNewWords ?? 10;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PlanSettingsSheet(
        currentNewWords: currentNewWords,
        onConfirm: (newCount) async {
          final storage = ref.read(progressStorageProvider);
          await storage.savePlanSettings(
            bookId: ref.read(currentBookIdProvider),
            examDate: DateTime.now().add(const Duration(days: 90)),
            dailyMinutes: 30,
            dailyNewWords: newCount,
          );
          setState(() => _userDailyNewWords = newCount);
          _initPlan();
        },
      ),
    );
  }
}

/// 学习计划设置弹窗
class _PlanSettingsSheet extends StatefulWidget {
  final int currentNewWords;
  final void Function(int newCount) onConfirm;

  const _PlanSettingsSheet({
    required this.currentNewWords,
    required this.onConfirm,
  });

  @override
  State<_PlanSettingsSheet> createState() => _PlanSettingsSheetState();
}

class _PlanSettingsSheetState extends State<_PlanSettingsSheet> {
  late int _selectedNewWords;

  static const _presets = [0, 5, 10, 15, 20, 30, 50];

  @override
  void initState() {
    super.initState();
    _selectedNewWords = widget.currentNewWords.clamp(0, 50);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部拖拽条
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '调整学习计划',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            '每天学习新词数量，复习词由系统自动安排',
            style: TextStyle(color: colors.inkSoft, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // 每日新词量选择
          const Text(
            '每日新词',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((count) {
              final selected = count == _selectedNewWords;
              return ChoiceChip(
                label: count == 0 ? const Text('佛系躺平') : Text('$count 词'),
              selected: selected,
              onSelected: (_) => setState(() => _selectedNewWords = count),
              selectedColor: colors.mintBg,
              labelStyle: TextStyle(
                color: selected
                    ? colors.ink
                    : colors.inkSoft,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color:
                    selected ? colors.mintDeep : colors.border,
              ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 自定义滑块
          Row(
            children: [
              Text('0',
                  style:
                      TextStyle(color: colors.inkSoft, fontSize: 12)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.mintDeep,
                      inactiveTrackColor: colors.mintBg,
                      thumbColor: colors.mintDeep,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: _selectedNewWords.toDouble(),
                    min: 0,
                    max: 50,
                    divisions: 10,
                    onChanged: (v) =>
                        setState(() => _selectedNewWords = v.round()),
                  ),
                ),
              ),
              Text('50',
                  style:
                      TextStyle(color: colors.inkSoft, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),

          // 预估提示
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                    colors.mintDeep.withValues(alpha: 0.08),
                    colors.mintDeep.withValues(alpha: 0.06),
                  ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.mintBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.schedule_rounded,
                      size: 16, color: colors.mintDeep),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedNewWords == 0
                        ? '今天就和老朋友叙叙旧，不见新朋友啦🌿'
                        : '预计每天学习 ${(_selectedNewWords * 0.7).round()} 分钟',
                    style: TextStyle(
                        fontSize: 13,
                        color: colors.ink,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 确认按钮（渐变）
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: colors.headerGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colors.mintDeep.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  widget.onConfirm(_selectedNewWords);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '确定',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
