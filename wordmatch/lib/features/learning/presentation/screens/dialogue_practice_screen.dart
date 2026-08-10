import 'package:flutter/material.dart';
import 'package:wordmatch/core/constants/app_colors.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/ai/data/services/ai_client.dart';
import 'package:wordmatch/features/ai/data/services/ai_learning_service.dart';
import 'package:wordmatch/shared/utils/audio_player.dart';
import 'package:wordmatch/shared/utils/haptic_util.dart';
import 'package:wordmatch/shared/widgets/gradient_page_header.dart';

/// 口语对话练习页面参数
class DialoguePracticeArgs {
  final String wordId;
  final String word;
  final List<String> definition;

  const DialoguePracticeArgs({
    required this.wordId,
    required this.word,
    required this.definition,
  });
}

/// AI 口语对话练习页面
///
/// 展示围绕目标单词生成的情景对话，支持逐句 TTS 播放与跟读。
class DialoguePracticeScreen extends StatefulWidget {
  final DialoguePracticeArgs args;

  const DialoguePracticeScreen({super.key, required this.args});

  @override
  State<DialoguePracticeScreen> createState() => _DialoguePracticeScreenState();
}

class _DialoguePracticeScreenState extends State<DialoguePracticeScreen> {
  DialogueResult _result = const DialogueResult();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDialogue();
  }

  Future<void> _loadDialogue() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final result = await AiLearningService.generateDialogue(
      widget.args.wordId,
      widget.args.definition,
    );

    if (!mounted) return;
    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  Future<void> _speakLine(String text) async {
    HapticUtil.buttonTap();
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

  Future<void> _speakAll() async {
    HapticUtil.buttonTap();
    for (final line in _result.lines) {
      final result = await AudioPlayerUtil.speakSentence(line.en);
      if (!result.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? '播放失败'),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      // 两句之间留出短暂停顿，便于用户跟读
      await Future.delayed(const Duration(milliseconds: 700));
    }
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
            GradientPageHeader(
            title: '口语对话练习',
            subtitle: '和 AI 来一场地道对话',
            trailing: !_isLoading && _result.lines.isNotEmpty
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.playlist_play_rounded),
                      color: Colors.white,
                      tooltip: '播放全部',
                      onPressed: _speakAll,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  )
                : null,
          ),
          // 头部：目标单词与情景
          _buildHeader(args),

          // 对话内容
          Expanded(
            child: _isLoading ? _buildLoading() : _buildContent(),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildHeader(DialoguePracticeArgs args) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSizes.pagePaddingH),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: colors.headerGradient,
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
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_result.phonetic.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _result.phonetic,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            args.definition.map((d) {
              return d.replaceFirst(RegExp(r'^[a-z]+\.\s'), '');
            }).join('；'),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          if (_result.scenario.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.theaters_outlined,
                    size: 14,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _result.scenario,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoading() {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 16),
          Text(
            'AI 正在生成对话…',
            style: TextStyle(
              fontSize: 14,
              color: colors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_result.lines.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePaddingH),
      itemCount: _result.lines.length,
      itemBuilder: (context, index) {
        final line = _result.lines[index];
        final isA = line.speaker.toUpperCase() == 'A';
        return _buildDialogueBubble(line, isA: isA);
      },
    );
  }

  Widget _buildEmptyState() {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePaddingH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.record_voice_over_outlined,
              size: 56,
              color: colors.inkSoft.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              AiClient.isConfigured
                  ? 'AI 对话生成失败，点击重试'
                  : '配置 API Key 后可使用口语对话练习',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colors.inkSoft.withValues(alpha: 0.85),
              ),
            ),
            if (AiClient.isConfigured) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadDialogue,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重新生成'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.mintDeep,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDialogueBubble(DialogueLine line, {required bool isA}) {
    final colors = context.appColors;
    final bubbleColor = isA
        ? colors.card
        : colors.mintDeep.withValues(alpha: 0.08);
    final accentColor = isA ? colors.mintDeep : AppColors.success;

    return Align(
      alignment: isA ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isA ? 4 : 16),
              bottomRight: Radius.circular(isA ? 16 : 4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        line.speaker,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isA ? '角色 A' : '角色 B',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.inkSoft.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                line.en,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: colors.ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                line.zh,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: colors.inkSoft.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    icon: Icons.volume_up_rounded,
                    label: '播放',
                    onTap: () => _speakLine(line.en),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.record_voice_over_rounded,
                    label: '跟读',
                    onTap: () => _speakLine(line.en),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.mintDeep.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: colors.mintDeep,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.mintDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
