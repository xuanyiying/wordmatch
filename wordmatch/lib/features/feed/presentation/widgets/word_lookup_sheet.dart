import 'package:flutter/material.dart';

import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/wordbook/data/repositories/custom_wordbook_repository.dart';
import 'package:wordmatch/features/wordbook/data/services/custom_wordbook_importer.dart';
import 'package:wordmatch/shared/utils/audio_player.dart';

import '../../data/services/dictionary_service.dart';
import '../../data/services/semantic_annotator_service.dart';

/// 点词查词底部卡片（掰it 风格）：
/// 单词 + 音标 + 语境义项（置顶）+ 词典释义 + 发音 + 收藏到阅读生词本
///
/// 查词顺序为 AI 优先：文章分析缓存中的语境义 → 按需 AI 查词（结果写回
/// 文章缓存）→ 离线词典兜底；全部失败但已有语境义时仍展示语境义。
Future<void> showWordLookupSheet(
  BuildContext context, {
  required String word,
  String? contextGloss,
  String? sentence,
  required bool alreadySaved,
  required VoidCallback onSaved,
  String? sourceId,
  String? articleId,
  void Function(String word, String gloss)? onGlossResolved,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _WordLookupSheet(
      word: word,
      contextGloss: contextGloss,
      sentence: sentence,
      alreadySaved: alreadySaved,
      onSaved: onSaved,
      sourceId: sourceId,
      articleId: articleId,
      onGlossResolved: onGlossResolved,
    ),
  );
}

class _WordLookupSheet extends StatefulWidget {
  final String word;
  final String? contextGloss;
  final String? sentence;
  final bool alreadySaved;
  final VoidCallback onSaved;
  final String? sourceId;
  final String? articleId;
  final void Function(String word, String gloss)? onGlossResolved;

  const _WordLookupSheet({
    required this.word,
    this.contextGloss,
    this.sentence,
    required this.alreadySaved,
    required this.onSaved,
    this.sourceId,
    this.articleId,
    this.onGlossResolved,
  });

  @override
  State<_WordLookupSheet> createState() => _WordLookupSheetState();
}

class _WordLookupSheetState extends State<_WordLookupSheet> {
  late Future<WordLookup?> _future;
  late bool _saved;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _saved = widget.alreadySaved;
    _future = _resolve();
  }

  /// AI 优先解析：
  /// 1. 整篇文章分析/批量释义已缓存的语境义 → 零网络直接展示（用词典补音标）
  /// 2. 无缓存 → 带所在句调 AI 查词，结果写回文章 gloss 缓存供行内括注复用
  /// 3. AI 未配置/额度不足/失败 → 离线词典兜底
  /// 4. 都没有但手里有语境义 → 至少展示语境义，不再误报「未查到」
  Future<WordLookup?> _resolve() async {
    final word = widget.word;
    final cachedGloss =
        (widget.contextGloss ?? '').trim().isEmpty ? null : widget.contextGloss;
    final local = await DictionaryService.lookupLocal(word);

    if (cachedGloss != null) {
      return _withGloss(word, local, cachedGloss);
    }

    final ai = await DictionaryService.lookupAi(word, sentence: widget.sentence);
    if (ai != null) {
      final gloss = (ai.inContext ?? '').isNotEmpty
          ? ai.inContext!
          : (ai.definitions.isNotEmpty ? ai.definitions.first : '');
      final sid = widget.sourceId;
      final aid = widget.articleId;
      if (gloss.isNotEmpty && sid != null && aid != null) {
        await SemanticAnnotatorService.saveGloss(
          sourceId: sid,
          articleId: aid,
          word: word,
          gloss: gloss,
        );
      }
      widget.onGlossResolved?.call(word, gloss);
      return ai;
    }

    if (local != null) return local;
    return null;
  }

  /// 把已有语境义置顶，离线词典补音标与通用义项；词典也没有时仅用语境义。
  WordLookup _withGloss(String word, WordLookup? local, String gloss) =>
      WordLookup(
        word: word,
        phonetic: local?.phonetic,
        definitions: [
          '语境义：$gloss',
          ...?local?.definitions.take(2),
        ],
        origin: 'ai',
      );

  Future<void> _speak() async {
    if (_speaking) return;
    setState(() => _speaking = true);
    final result = await AudioPlayerUtil.speakWord(widget.word);
    if (mounted && !result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? '发音失败')),
      );
    }
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _save() async {
    if (_saved) return;
    final lookup = await _future;
    final repo = CustomWordbookRepository();
    final ok = await repo.appendWords(
      CustomWordbookRepository.readingBookId,
      [
        ImportedWord(
          word: widget.word,
          phonetic: lookup?.phonetic,
          definition: _definitionsFor(lookup),
        ),
      ],
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _saved = true);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已加入「阅读生词本」')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('收藏失败，请重试')),
      );
    }
  }

  List<String> _definitionsFor(WordLookup? lookup) {
    if (widget.contextGloss != null && widget.contextGloss!.isNotEmpty) {
      return [widget.contextGloss!,
        ...?lookup?.definitions.take(2),
      ];
    }
    return lookup?.definitions.take(3).toList() ?? const ['（待补充释义）'];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行：单词 + 发音
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.word,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _speak,
                  icon: Icon(
                    _speaking ? Icons.volume_up : Icons.volume_up_outlined,
                    color: colors.mintDeep,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // 查词结果
            FutureBuilder<WordLookup?>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.inkFaint,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('查询中…',
                            style: TextStyle(
                                fontSize: 13, color: colors.inkFaint)),
                      ],
                    ),
                  );
                }
                final lookup = snap.data;
                if (lookup == null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('未查到该词，请检查拼写或稍后再试',
                        style:
                            TextStyle(fontSize: 14, color: colors.inkSoft)),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lookup.phonetic != null &&
                        lookup.phonetic!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '/${lookup.phonetic}/',
                          style: TextStyle(
                              fontSize: 14, color: colors.mintDeep),
                        ),
                      ),
                    // 首条为语境义（AI）或最常用义（词典），置顶强调
                    for (var i = 0; i < lookup.definitions.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 3,
                              height: 14,
                              margin: const EdgeInsets.only(top: 4, right: 8),
                              decoration: BoxDecoration(
                                color: i == 0 ? colors.amber : colors.mintLight,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                lookup.definitions[i],
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: colors.ink,
                                  fontWeight: i == 0
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (lookup.example != null &&
                        lookup.example!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          lookup.example!,
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                            color: colors.inkFaint,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // 收藏按钮
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saved ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.mintDeep,
                  foregroundColor: colors.card,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(_saved ? Icons.check : Icons.bookmark_add_outlined,
                    size: 18),
                label: Text(
                  _saved ? '已在生词本' : '加入阅读生词本',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
