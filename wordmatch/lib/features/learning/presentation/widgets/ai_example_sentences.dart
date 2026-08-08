import 'package:flutter/material.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/core/subscription/subscription_service.dart';
import 'package:wordmatch/core/subscription/upgrade_pro_dialog.dart';
import 'package:wordmatch/features/ai/data/services/ai_client.dart';
import 'package:wordmatch/features/ai/data/services/ai_learning_service.dart';
import 'package:wordmatch/shared/widgets/speak_button.dart';

/// AI 例句展示组件
///
/// 自动加载目标单词的 AI 例句，支持播放音频与高亮目标词。
class AiExampleSentences extends StatefulWidget {
  final String wordId;
  final String word;
  final List<String> definition;

  const AiExampleSentences({
    super.key,
    required this.wordId,
    required this.word,
    required this.definition,
  });

  @override
  State<AiExampleSentences> createState() => _AiExampleSentencesState();
}

class _AiExampleSentencesState extends State<AiExampleSentences> {
  List<AiExampleSentence> _sentences = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSentences();
  }

  Future<void> _loadSentences() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AiLearningService.generateExampleSentences(
      widget.wordId,
      widget.definition,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _sentences = result;
      if (result.isEmpty && AiClient.isConfigured) {
        _error = 'AI 例句生成失败';
      }
    });

    if (result.isEmpty && AiClient.isConfigured && mounted) {
      final q = await SubscriptionService.getAiQuota();
      if (!mounted) return;
      if (q.$1 >= q.$2 && q.$2 != -1) {
        showUpgradeProDialog(context, reason: '今日 AI 额度已用完');
      }
    }
  }

  List<TextSpan> _buildEnSpans(String en) {
    final colors = context.appColors;
    final spans = <TextSpan>[];
    // AI 可能给目标词及其变体/相关词都加 ***...*** 标记，
    // 用通用正则匹配任意 ***...***，剥离标记并高亮内部词，
    // 避免出现字面量 ***（旧实现只匹配目标词，其它词会泄漏 ***）。
    final pattern = RegExp(r'\*\*\*([^*]+?)\*\*\*', caseSensitive: false);

    var current = en;
    while (true) {
      final match = pattern.firstMatch(current);
      if (match == null) {
        spans.add(TextSpan(text: current));
        break;
      }

      if (match.start > 0) {
        spans.add(TextSpan(text: current.substring(0, match.start)));
      }

      // 去除 *** 标记，还原被高亮的单词
      final cleanWord = match.group(1)!;
      spans.add(
        TextSpan(
          text: cleanWord,
          style: TextStyle(
            color: colors.mintDeep,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      current = current.substring(match.end);
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'AI 正在生成例句…',
              style: TextStyle(fontSize: 13, color: colors.inkSoft),
            ),
          ],
        ),
      );
    }

    if (_sentences.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: colors.inkSoft.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error ?? '暂无例句，配置 API Key 后可使用 AI 生成',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.inkSoft.withValues(alpha: 0.8),
                ),
              ),
            ),
            if (_error != null)
              TextButton(
                onPressed: _loadSentences,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('重试', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 音标（取第一条例句的 phonetic）
        if (_sentences.isNotEmpty && _sentences.first.phonetic.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(
                  Icons.record_voice_over_outlined,
                  size: 14,
                  color: colors.mintDeep.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  _sentences.first.phonetic,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.mintDeep.withValues(alpha: 0.85),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ..._sentences.map((sentence) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 英文例句 + 播放按钮
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: colors.ink,
                          ),
                          children: _buildEnSpans(sentence.en),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SpeakButton(
                      text: sentence.en,
                      color: colors.mintDeep,
                      size: 26,
                      iconSize: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 中文翻译
                Text(
                  sentence.zh,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: colors.inkSoft.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
