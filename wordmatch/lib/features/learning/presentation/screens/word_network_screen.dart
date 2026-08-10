import 'package:flutter/material.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/router/app_router.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/ai/data/services/ai_client.dart';
import 'package:wordmatch/features/ai/data/services/ai_learning_service.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';
import 'package:wordmatch/features/wordbook/data/repositories/word_repository.dart';
import 'package:wordmatch/shared/widgets/gradient_page_header.dart';

/// 同义词/反义词网络页面参数
class WordNetworkArgs {
  final String wordId;
  final String word;
  final List<String> definition;

  const WordNetworkArgs({
    required this.wordId,
    required this.word,
    required this.definition,
  });
}

/// AI 同义词/反义词网络页面
class WordNetworkScreen extends StatefulWidget {
  final WordNetworkArgs args;

  const WordNetworkScreen({super.key, required this.args});

  @override
  State<WordNetworkScreen> createState() => _WordNetworkScreenState();
}

class _WordNetworkScreenState extends State<WordNetworkScreen> {
  WordNetworkResult _result = const WordNetworkResult();
  bool _isLoading = false;

  /// 词库仓库：用于把同反义词的纯词文本映射回完整 Word（命中时有音标/例句/词根）
  final WordRepository _repo = WordRepository();

  @override
  void initState() {
    super.initState();
    _loadNetwork();
  }

  Future<void> _loadNetwork() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final result = await AiLearningService.generateWordNetwork(
      widget.args.wordId,
      widget.args.definition,
    );

    if (!mounted) return;
    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  /// 点击同反义词 chip：优先在词库中查完整词条，命中用真实 Word，
  /// 未命中则用 NetworkWord 构造最小 Word 兜底；然后跳转 NewWordScreen 浏览模式。
  Future<void> _onChipTap(NetworkWord item) async {
    final full = await _repo.findByWordText(item.word);
    final Word w = full ??
        Word(
          id: 'network_${item.word}',
          word: item.word,
          definition: item.definition.isNotEmpty
              ? [item.definition]
              : const ['暂无释义'],
          bookId: '',
          frequency: 3,
        );
    if (!mounted) return;
    Navigator.of(context).pushNamed(
      AppRouter.newWord,
      arguments: NewWordArgs(
        words: [w],
        onComplete: () => Navigator.of(context).pop(),
        browseMode: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const GradientPageHeader(
                title: '同反义词网络', subtitle: '点击单词可跳转学习卡片'),
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 头部：目标单词
                SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.pagePaddingH),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.mintDeep,
                            colors.mintLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colors.mintDeep.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            args.word,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            args.definition.map((d) {
                              // 去掉词性前缀，只保留释义
                              return d.replaceFirst(
                                  RegExp(r'^[a-z]+\.\s'), '');
                            }).join('；'),
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'AI 正在构建词网络…',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 内容区
            if (!_isLoading) ...[
              _buildSection('同义词', _result.synonyms, colors.mintLight, colors),
              _buildSection('反义词', _result.antonyms, colors.amber, colors),
              _buildSection('相关词', _result.related, colors.mintDeep, colors),

              if (_result.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.pagePaddingH,
                      vertical: 40,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.sentiment_neutral_rounded,
                            size: 48,
                            color: colors.inkFaint.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AiClient.isConfigured
                                ? 'AI 网络生成失败，点击重试'
                                : '配置 API Key 后可查看同反义词网络',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  colors.inkSoft.withValues(alpha: 0.8),
                            ),
                          ),
                          if (AiClient.isConfigured) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _loadNetwork,
                              child: const Text('重试'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // 操作提示
              if (!_result.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.pagePaddingH,
                      0,
                      AppSizes.pagePaddingH,
                      12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded,
                            size: 13, color: colors.inkFaint),
                        const SizedBox(width: 4),
                        Text(
                          '点击单词可跳转学习卡片',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    ],
    ),
  ),
);
  }

  Widget _buildSection(
    String title,
    List<NetworkWord> words,
    Color color,
    AppColorScheme colors,
  ) {
    if (words.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePaddingH,
          0,
          AppSizes.pagePaddingH,
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${words.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: words
                  .map((item) => _buildWordChip(item, color, colors))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 单词 chip：可点击跳转 NewWordScreen 浏览模式
  Widget _buildWordChip(
    NetworkWord item,
    Color color,
    AppColorScheme colors,
  ) {
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _onChipTap(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.word,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 14, color: color.withValues(alpha: 0.6)),
                ],
              ),
              if (item.definition.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.definition,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.inkSoft.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
