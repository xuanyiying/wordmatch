import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/core/audio/sherpa_tts_engine.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/game/data/repositories/game_provider.dart';
import 'package:wordmatch/features/today/data/daily_content_service.dart';
import 'package:wordmatch/features/today/domain/models/daily_quote.dart';
import 'package:wordmatch/features/today/domain/models/daily_word.dart';
import 'package:wordmatch/features/today/presentation/providers/daily_content_provider.dart';
import 'package:wordmatch/shared/utils/audio_player.dart';
import 'package:wordmatch/shared/utils/haptic_util.dart';
import 'package:wordmatch/shared/widgets/gradient_page_header.dart';
import 'package:wordmatch/shared/widgets/speak_button.dart';

/// 今日页：连续打卡 + 今日进度 + 每日一词 + 每日一句
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  int _learnedToday = 0;
  int _newWordsTarget = 15;
  int _dueReview = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final storage = ref.read(progressStorageProvider);
    if (!storage.isInitialized) await storage.init();
    final taskState = storage.getDailyTaskState();
    final settings = storage.getPlanSettings();
    final due = storage
        .getAllProgress()
        .where((p) => !p.isMastered && !p.nextReviewDate.isAfter(DateTime.now()))
        .length;
    if (mounted) {
      setState(() {
        _learnedToday = taskState?.learnedWordIds.length ?? 0;
        _newWordsTarget = (settings?['dailyNewWords'] as int?) ?? 15;
        _dueReview = due;
        _loading = false;
      });
    }
  }

  Future<void> _speak(String text) async {
    final result = await AudioPlayerUtil.speakSentence(text);
    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? '播放失败'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 拆解学词：将每日一句拆成单词，逐个学习发音
  void _showWordBreakdown(DailyQuote q) {
    // 常见虚词/停用词，聚焦实义词
    const stopWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'is', 'are', 'was', 'were',
      'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did',
      'of', 'in', 'on', 'at', 'to', 'for', 'with', 'by', 'from', 'as',
      'that', 'this', 'these', 'those', 'it', 'its', 'he', 'she', 'we',
      'they', 'you', 'i', 'not', 'no', 'so', 'if', 'than', 'then',
      'can', 'could', 'will', 'would', 'should', 'may', 'might', 'must',
      'what', 'who', 'whom', 'which', 'how', 'why', 'when', 'where',
      'us', 'our', 'my', 'me', 'him', 'his', 'her', 'their', 'them',
      'some', 'any', 'all', 'each', 'every', 'other', 'such', 'own',
      'about', 'into', 'out', 'up', 'down', 'over', 'under', 'again',
    };
    final words = RegExp(r"[a-zA-Z']+")
        .allMatches(q.text)
        .map((m) => m.group(0)!.toLowerCase())
        .where((w) => w.length >= 2 && !stopWords.contains(w))
        .toSet()
        .toList();

    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.72,
          ),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽指示条
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
                child: Row(
                  children: [
                    Icon(Icons.spellcheck,
                        size: 18, color: colors.amber),
                    const SizedBox(width: 6),
                    Text('拆解学词',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.ink)),
                    const Spacer(),
                    Text('${words.length} 个实义词',
                        style: TextStyle(
                            fontSize: 11, color: colors.inkFaint)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text('"${q.text}"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        color: colors.inkSoft,
                        fontStyle: FontStyle.italic,
                        height: 1.5)),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: words.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text('这句没有可拆解的实义词',
                            style: TextStyle(
                                fontSize: 13, color: colors.inkFaint)),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                        itemCount: words.length,
                        separatorBuilder: (_, __) =>
                            Container(height: 1, color: colors.divider),
                        itemBuilder: (ctx, i) {
                          final w = words[i];
                          return InkWell(
                            onTap: () => _speak(w),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 11),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: colors.amberBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('${i + 1}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: colors.amber)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(w,
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: colors.ink)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: colors.amberBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.volume_up,
                                        size: 16, color: colors.amber),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[now.weekday - 1];
    final wordAsync = ref.watch(dailyWordProvider);
    final wordOverride = ref.watch(dailyWordOverrideProvider);
    final quoteAsync = ref.watch(dailyQuoteProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _initData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildHeader('${now.month}月${now.day}日 · $weekday'),
                    _buildTtsBanner(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [                         
                          const SizedBox(height: 8),
                          _buildTodayProgress(),
                          const SizedBox(height: 8),
                          wordOverride != null
                              ? _buildWordCard(wordOverride)
                              : wordAsync.when(
                                  data: (w) => _buildWordCard(w),
                                  loading: () => const SizedBox(
                                    height: 140,
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  ),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                          const SizedBox(height: 8),
                          quoteAsync.when(
                            data: (q) => _buildQuoteCard(q),
                            loading: () => const SizedBox(
                              height: 140,
                              child:
                                  Center(child: CircularProgressIndicator()),
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(String subtitle) {
    return GradientPageHeader(
      title: '今日',
      subtitle: subtitle,
      showBackButton: false,
    );
  }

  /// 离线语音引擎进度/错误条：引擎就绪后自动隐藏。
  ///
  /// 三种状态：
  /// - **就绪**：隐藏
  /// - **解压中**：显示进度条 + 百分比
  /// - **失败**：显示错误文案 + 「重试」按钮（旧实现只设了 status 但从不显示，
  ///   用户永远看到"正在准备…"，无法知道已失败也无法重试）
  Widget _buildTtsBanner() {
    final colors = context.appColors;
    return ValueListenableBuilder<bool>(
      valueListenable: SherpaTtsEngine.instance.ready,
      builder: (_, isReady, __) {
        if (isReady) return const SizedBox.shrink();
        return ValueListenableBuilder<String?>(
          valueListenable: SherpaTtsEngine.instance.status,
          builder: (_, status, ___) {
            final isError = status != null && status.contains('失败');
            if (isError) {
              return _buildTtsErrorBanner(status);
            }
            return ValueListenableBuilder<double>(
              valueListenable: SherpaTtsEngine.instance.progress,
              builder: (_, p, __) {
                final pct = (p * 100).clamp(0, 100).toInt();
                return Container(
                  margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.mintBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: colors.mintDeep.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: p > 0 ? p : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p > 0
                              ? '正在准备离线语音引擎 $pct%（仅需一次）…'
                              : '正在准备离线语音引擎…',
                          style: TextStyle(
                              fontSize: 11, color: colors.mintDeep),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// TTS 解压失败时的错误横幅，带「重试」按钮。
  Widget _buildTtsErrorBanner(String status) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE57373).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Color(0xFFE57373)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status,
              style: const TextStyle(fontSize: 11, color: Color(0xFFC62828)),
            ),
          ),
          GestureDetector(
            onTap: () {
              // 重新触发解压（ensureReady 内部会清除旧目录后重新提取）
              SherpaTtsEngine.instance.ensureReady();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE57373),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '重试',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayProgress() {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.insights, size: 16, color: colors.mintDeep),
            const SizedBox(width: 5),
            Text('今日进度',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: colors.ink)),
          ]),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: colors.mintBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('$_learnedToday/$_newWordsTarget',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colors.ink)),
                      Text('新词',
                          style: TextStyle(fontSize: 10, color: colors.inkSoft)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: colors.amberBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('$_dueReview',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colors.amber)),
                      Text('待复习',
                          style: TextStyle(fontSize: 10, color: colors.inkSoft)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(DailyWord w) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
        boxShadow: const [
          BoxShadow(color: Color(0x0D0F2E0F), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.mintBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(children: [
                  Icon(Icons.star, size: 11, color: colors.mintDeep),
                  const SizedBox(width: 3),
                  Text('每日一词 · 高频考点',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colors.mintDeep)),
                ]),
              ),
              const Spacer(),
              Text(_dateLabel(),
                  style: TextStyle(fontSize: 10, color: colors.inkFaint)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(w.word,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: colors.ink)),
              const SizedBox(width: 10),
              Text(w.phonetic,
                  style: TextStyle(fontSize: 12, color: colors.inkSoft)),
              const Spacer(),
              SpeakButton(
                text: w.word,
                color: colors.mintDeep,
                size: 30,
                iconSize: 16,
                icon: Icons.volume_up,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${w.pos} ${w.meaning}',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: colors.mintDeep)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.mintBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.mintLight.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text('"${w.example}"',
                          style: TextStyle(fontSize: 12, color: colors.ink, height: 1.6)),
                    ),
                    if (w.example.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      SpeakButton(
                        text: w.example,
                        color: colors.mintDeep,
                        size: 28,
                        iconSize: 14,
                        icon: Icons.volume_up,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(w.exampleTrans,
                    style: TextStyle(fontSize: 12, color: colors.inkSoft, height: 1.6)),
                if (w.source.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('📝 ${w.source}',
                      style: TextStyle(fontSize: 12, color: colors.inkFaint)),
                ],
              ],
            ),
          ),
          // 按钮行：换一个 + 加入生词本
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _wordFooterButton(
                  icon: Icons.refresh_rounded,
                  label: '换一个',
                  isPrimary: false,
                  onTap: () async {
                    HapticUtil.buttonTap();
                    final next = await DailyContentService.getRandomWord(w);
                    if (mounted) {
                      ref.read(dailyWordOverrideProvider.notifier).set(next);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _wordFooterButton(
                  icon: Icons.add_rounded,
                  label: '加入生词本',
                  isPrimary: true,
                  onTap: () async {
                    HapticUtil.buttonTap();
                    final storage = ref.read(progressStorageProvider);
                    await storage.addWrongWord(
                      wordId: '${w.word}_daily',
                      bookId: 'daily',
                      context: '每日一词收藏',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已将「${w.word}」加入生词本'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 每日一词卡片底部按钮
  Widget _wordFooterButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  colors: [colors.mintLight, colors.mintDeep],
                )
              : null,
          color: isPrimary ? null : colors.divider,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(color: colors.border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14,
                color: isPrimary ? colors.ink : colors.inkSoft),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? colors.ink : colors.inkSoft,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard(DailyQuote q) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.amberBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(children: [
              Icon(Icons.format_quote, size: 11, color: colors.amber),
              const SizedBox(width: 3),
              Text('每日一句 · 经典台词',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.amber)),
            ]),
          ),
          const SizedBox(height: 12),
          Text('"${q.text}"',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                  height: 1.55,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Text(q.trans,
              style: TextStyle(fontSize: 12, color: colors.inkSoft, height: 1.6)),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: Text(q.work,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: colors.ink)),
              ),
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 12, height: 1, color: colors.amber.withValues(alpha: 0.5)),
              Flexible(
                child: Text(q.author,
                    style: TextStyle(fontSize: 11, color: colors.amber)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _speak(q.text),
                  icon: Icon(Icons.volume_up, size: 14, color: colors.amber),
                  label: Text('听朗读',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.amber)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.card,
                    foregroundColor: colors.amber,
                    elevation: 0,
                    side: BorderSide(color: colors.amber.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showWordBreakdown(q),
                  icon: const Icon(Icons.spellcheck, size: 14, color: Colors.white),
                  label: const Text('拆解学词',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.amber,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateLabel() {
    final now = DateTime.now();
    return '${now.month}月${now.day}日';
  }
}
