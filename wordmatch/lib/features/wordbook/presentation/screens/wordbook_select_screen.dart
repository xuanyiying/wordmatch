import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/core/constants/app_colors.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/router/app_router.dart';
import 'package:wordmatch/features/game/data/repositories/game_provider.dart';
import 'package:wordmatch/features/wordbook/data/datasources/local_word_datasource.dart';

/// 词库选择页面
class WordbookSelectScreen extends ConsumerStatefulWidget {
  const WordbookSelectScreen({super.key});

  @override
  ConsumerState<WordbookSelectScreen> createState() =>
      _WordbookSelectScreenState();
}

class _WordbookSelectScreenState extends ConsumerState<WordbookSelectScreen> {
  late Future<List<BookInfo>> _booksFuture;
  late Future<List<BookInfo>> _removedBooksFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _booksFuture = ref.read(wordbookRepositoryProvider).getAvailableBooks();
      _removedBooksFuture =
          ref.read(wordbookRepositoryProvider).getRemovedBuiltinBooks();
    });
  }

  Future<void> _onDeleteBook(BookInfo book) async {
    final isCustom = book.isCustom;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('删除词库？'),
        content: Text(
          isCustom
              ? '确定要删除「${book.name}」吗？此操作不可撤销。'
              : '确定要删除「${book.name}」吗？删除后将不再显示在词库列表中，可随时在页面底部恢复。',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final repo = ref.read(wordbookRepositoryProvider);
      await repo.removeBook(book.id);
      repo.clearCache();
      _refresh();
      // 若删除的是当前使用的词库，切换到其它可用词库
      final currentBookId = ref.read(currentBookIdProvider);
      if (book.id == currentBookId) {
        final available = await repo.getAvailableBooks();
        if (available.isNotEmpty) {
          final fallback = available.firstWhere(
            (b) => b.available,
            orElse: () => available.first,
          );
          await ref.read(currentBookIdProvider.notifier).setBookId(fallback.id);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除「${book.name}」')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: FutureBuilder<List<BookInfo>>(
          future: _booksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snapshot.data ?? [];
            final builtIn = all.where((b) => !b.isCustom).toList();
            final customs = all.where((b) => b.isCustom).toList();

            return Column(
              children: [
                // 渐变头部
                _buildHeader(context),
                // 内容列表
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.pagePaddingH,
                      16,
                      AppSizes.pagePaddingH,
                      24,
                    ),
                    children: [
                      // 导入入口卡
                      _buildImportCard(context),
                      const SizedBox(height: 20),

                      // 自定义词库分组
                      if (customs.isNotEmpty) ...[
                        _buildSectionHeader('自定义词库', count: customs.length),
                        const SizedBox(height: 10),
                        for (final b in customs) ...[
                          _buildWordbookCard(
                            context: context,
                            book: b,
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 12),
                      ],

                      // 内置词库分组
                      _buildSectionHeader('内置词库', count: builtIn.length),
                      const SizedBox(height: 10),
                      for (final b in builtIn) ...[
                        _buildWordbookCard(
                          context: context,
                          book: b,
                        ),
                        const SizedBox(height: 10),
                      ],

                      // 已删除（隐藏）词库恢复入口
                      if (builtIn.isNotEmpty) const SizedBox(height: 12),
                      FutureBuilder<List<BookInfo>>(
                        future: _removedBooksFuture,
                        builder: (context, removedSnapshot) {
                          final removed =
                              removedSnapshot.data ?? const <BookInfo>[];
                          if (removed.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return _buildRestoreSection(context, removed);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 渐变头部
  Widget _buildHeader(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.mintDeep, Color(0xFF3A6C28)],
        ),
        borderRadius: const BorderRadius.only(
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择词库',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '根据你的考试目标选择，或导入自定义词库',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 已删除（隐藏）词库的恢复区块
  Widget _buildRestoreSection(BuildContext context, List<BookInfo> removed) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('已删除词库', count: removed.length),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final b in removed) ...[
                Row(
                  children: [
                    Icon(Icons.restore_rounded,
                        size: 18, color: colors.inkSoft),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b.name,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.inkSoft),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(wordbookRepositoryProvider)
                            .restoreBook(b.id);
                        _refresh();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colors.mintDeep,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('恢复'),
                    ),
                  ],
                ),
                if (b != removed.last)
                  Divider(height: 1, color: colors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {required int count}) {
    final colors = context.appColors;
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: colors.mintDeep,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.ink)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colors.mintDeep.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$count',
              style: TextStyle(
                  fontSize: 11,
                  color: colors.mintDeep,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildImportCard(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentOrange.withValues(alpha: 0.08),
            const Color(0xFFFBBF24).withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentOrange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result =
                await Navigator.of(context).pushNamed(AppRouter.importWordbook);
            if (result == true) _refresh();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.file_upload_outlined,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('导入自定义词库',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('支持 JSON / CSV，至少 4 词',
                          style: TextStyle(
                              fontSize: 12, color: colors.inkSoft)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.accentOrange, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordbookCard({
    required BuildContext context,
    required BookInfo book,
  }) {
    final colors = context.appColors;
    final disabled = !book.available;
    final config = _bookConfig(book.id);
    final isCustom = book.isCustom;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: config.color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : () => Navigator.of(context).pop(book.id),
            onLongPress: () => _onDeleteBook(book),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 图标
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: disabled
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: config.gradientColors,
                            ),
                      color: disabled ? Colors.grey[300] : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(config.icon,
                        color: disabled ? Colors.grey[500] : Colors.white,
                        size: 26),
                  ),
                  const SizedBox(width: 16),
                  // 文字信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: disabled
                                ? colors.inkSoft
                                : colors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.available
                              ? '${book.wordCount} 词 · ${config.tag}'
                              : '即将开放 · ${book.wordCount} 词',
                          style: TextStyle(
                              fontSize: 12, color: colors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  // 词数 + 删除操作
                  if (!isCustom && disabled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${book.wordCount}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.inkSoft,
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: config.color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${book.wordCount}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: config.color,
                              ),
                            ),
                          ),
                        IconButton(
                          onPressed: () => _onDeleteBook(book),
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 20, color: colors.inkSoft),
                          tooltip: '删除',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 词库视觉配置
  _BookVisualConfig _bookConfig(String bookId) {
    final colors = context.appColors;
    switch (bookId) {
      case 'gaokao':
        return _BookVisualConfig(
          icon: Icons.school_rounded,
          color: colors.mintDeep,
          gradientColors: [colors.mintDeep, Color(0xFF3A6C28)],
          tag: '高中必备',
        );
      case 'cet4':
        return const _BookVisualConfig(
          icon: Icons.menu_book_rounded,
          color: Color(0xFF0891B2),
          gradientColors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
          tag: '大学四级',
        );
      case 'cet6':
        return const _BookVisualConfig(
          icon: Icons.auto_stories_rounded,
          color: Color(0xFF8B7355),
          gradientColors: [Color(0xFF8B7355), Color(0xFF6B5030)],
          tag: '大学六级',
        );
      case 'kaoyan':
        return const _BookVisualConfig(
          icon: Icons.workspace_premium_rounded,
          color: Color(0xFFDC2626),
          gradientColors: [Color(0xFFDC2626), Color(0xFFEF4444)],
          tag: '研究生入学',
        );
      case 'it':
        return const _BookVisualConfig(
          icon: Icons.computer_rounded,
          color: Color(0xFF059669),
          gradientColors: [Color(0xFF059669), Color(0xFF10B981)],
          tag: 'IT技术',
        );
      default:
        return const _BookVisualConfig(
          icon: Icons.book_rounded,
          color: AppColors.accentOrange,
          gradientColors: [Color(0xFFF97316), Color(0xFFFBBF24)],
          tag: '自定义',
        );
    }
  }
}

/// 词库视觉配置
class _BookVisualConfig {
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;
  final String tag;

  const _BookVisualConfig({
    required this.icon,
    required this.color,
    required this.gradientColors,
    required this.tag,
  });
}
