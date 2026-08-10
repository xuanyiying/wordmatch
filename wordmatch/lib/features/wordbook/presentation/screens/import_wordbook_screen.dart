import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/core/constants/app_colors.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/game/data/repositories/game_provider.dart';
import 'package:wordmatch/features/wordbook/data/services/ai_clean_service.dart';
import 'package:wordmatch/features/wordbook/data/services/custom_wordbook_importer.dart';
import 'package:wordmatch/shared/widgets/gradient_page_header.dart';

/// 自定义词库导入屏幕（支持 AI 清洗）
class ImportWordbookScreen extends ConsumerStatefulWidget {
  const ImportWordbookScreen({super.key});

  @override
  ConsumerState<ImportWordbookScreen> createState() =>
      _ImportWordbookScreenState();
}

class _ImportWordbookScreenState extends ConsumerState<ImportWordbookScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _error;
  String? _success;
  int _parsedCount = 0;
  String? _detectedFormat;

  // AI 清洗相关状态
  AiCleanStatus _aiStatus = AiCleanStatus.idle;
  List<AiCleanedWord> _aiCleanedWords = [];
  String? _aiStatusMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// 执行 AI 清洗
  Future<void> _onAiClean() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _error = '请先粘贴词库内容');
      return;
    }

    setState(() {
      _aiStatus = AiCleanStatus.loading;
      _error = null;
      _success = null;
      _aiStatusMessage = 'AI 正在清洗文本，请稍候…';
    });

    final result = await AiCleanService.cleanWithAi(content);

    if (!mounted) return;

    if (result.isSuccess && result.words.isNotEmpty) {
      setState(() {
        _aiStatus =
            result.usedAi ? AiCleanStatus.success : AiCleanStatus.fallback;
        _aiCleanedWords = result.words;
        _parsedCount = result.words.length;
        _aiStatusMessage = result.usedAi
            ? 'AI 清洗完成！耗时 ${result.elapsedMs}ms，提取 ${result.words.length} 个词条'
            : result.error ?? '已使用基础解析，提取 ${result.words.length} 个词条';
      });
    } else {
      // AI 失败但可能有降级结果
      if (result.words.isNotEmpty) {
        setState(() {
          _aiStatus = AiCleanStatus.fallback;
          _aiCleanedWords = result.words;
          _parsedCount = result.words.length;
          _aiStatusMessage = result.error ?? 'AI 处理失败，已降级到基础解析';
        });
      } else {
        setState(() {
          _aiStatus = AiCleanStatus.error;
          _aiStatusMessage = result.error ?? 'AI 清洗失败，请尝试手动调整格式';
        });
      }
    }
  }

  /// 使用 AI 清洗结果确认导入
  Future<void> _onConfirmAiImport() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请输入词库名称');
      return;
    }
    if (_aiCleanedWords.isEmpty) {
      setState(() => _error = '没有可导入的词条');
      return;
    }

    try {
      final importedWords =
          _aiCleanedWords.map((w) => w.toImportedWord()).toList();
      final repo = ref.read(wordbookRepositoryProvider);
      await repo.customRepo.save(name: name, words: importedWords);
      repo.clearCache();
      if (!mounted) return;
      setState(() => _success = '导入成功：${importedWords.length} 词');
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    } catch (e) {
      setState(() => _error = '保存失败：$e');
    }
  }

  /// 传统解析（不走 AI）
  void _onParse() {
    setState(() {
      _error = null;
      _success = null;
      _parsedCount = 0;
      _detectedFormat = null;
      _aiStatus = AiCleanStatus.idle;
      _aiCleanedWords = [];
    });
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _error = '请粘贴或输入词库内容');
      return;
    }
    String format;
    if (content.trimLeft().startsWith('{') ||
        content.trimLeft().startsWith('[')) {
      format = 'json';
    } else {
      format = 'csv';
    }
    final result = CustomWordbookImporter.parse(content, format,
        name: _nameController.text.trim());
    if (!result.isSuccess) {
      setState(() {
        _error = result.error;
        _detectedFormat = format;
      });
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _detectedFormat = format;
        _parsedCount = result.words.length;
        if (format == 'json') {
          _nameController.text = result.name;
        }
        _error = null;
      });
    } else {
      setState(() {
        _detectedFormat = format;
        _parsedCount = result.words.length;
      });
    }
  }

  /// 传统方式确认导入
  Future<void> _onConfirmImport() async {
    setState(() {
      _error = null;
      _success = null;
    });
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _error = '请先粘贴词库内容');
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请输入词库名称');
      return;
    }
    String format;
    if (content.trimLeft().startsWith('{') ||
        content.trimLeft().startsWith('[')) {
      format = 'json';
    } else {
      format = 'csv';
    }
    final parsed = CustomWordbookImporter.parse(content, format, name: name);
    if (!parsed.isSuccess) {
      setState(() => _error = parsed.error);
      return;
    }
    try {
      final repo = ref.read(wordbookRepositoryProvider);
      await repo.customRepo.save(name: name, words: parsed.words);
      repo.clearCache();
      if (!mounted) return;
      setState(() => _success = '导入成功：${parsed.words.length} 词');
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    } catch (e) {
      setState(() => _error = '保存失败：$e');
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() => _contentController.text = data!.text!);
    }
  }

  /// 从本地文件选择并读取词库内容。
  ///
  /// 支持 .txt / .json / .csv 文件：
  /// - `.json` / `.csv`：读取后自动识别格式并填入内容框，方便直接预览/导入
  /// - `.txt`：读取原始文本，适合用 AI 清洗
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'json', 'csv'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return; // 用户取消

      final file = result.files.single;
      if (file.bytes == null && file.path == null) {
        setState(() => _error = '无法读取所选文件');
        return;
      }

      // 优先用内存 bytes，否则从路径读取
      String content;
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else {
        final data = await File(file.path!).readAsBytes();
        content = utf8.decode(data);
      }
      content = content.trim();
      if (content.isEmpty) {
        setState(() => _error = '所选文件内容为空');
        return;
      }

      // 根据扩展名判定格式
      final ext = (file.extension ?? '').toLowerCase();
      final format = ext == 'json' ? 'json' : (ext == 'csv' ? 'csv' : null);

      // 重置旧状态，填入内容
      setState(() {
        _error = null;
        _success = null;
        _parsedCount = 0;
        _detectedFormat = null;
        _aiStatus = AiCleanStatus.idle;
        _aiCleanedWords = [];
        _aiStatusMessage = null;
        _contentController.text = content;
        // 未填名称时，用文件名作默认名称（去扩展名）
        if (_nameController.text.trim().isEmpty && file.name.isNotEmpty) {
          final base = file.name.contains('.')
              ? file.name.substring(0, file.name.lastIndexOf('.'))
              : file.name;
          _nameController.text = base.trim();
        }
      });

      // JSON / CSV 自动走传统解析；txt 提示用户用 AI 清洗
      if (format == 'json' || format == 'csv') {
        _onParse();
      } else {
        setState(() => _aiStatusMessage = '已读取 ${file.name}，点击「AI 清洗」提取词汇');
      }
    } catch (e) {
      setState(() => _error = '读取文件失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const GradientPageHeader(
              title: '导入自定义词库',
              subtitle: '支持文件 / 粘贴 / JSON / CSV，可用 AI 清洗',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.pagePaddingH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

            // 词库名
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '词库名称',
                hintText: '我的词库',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // 词库内容
            Row(
              children: [
                const Text('词库内容',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: const Text('从文件导入'),
                ),
                TextButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste, size: 16),
                  label: const Text('剪贴板'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _contentController,
              maxLines: 10,
              minLines: 6,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                hintText: '''粘贴杂乱文本，AI 自动清洗提取词汇

示例（从PDF复制的杂乱文本）：
1. abandon əˈbændən 放弃；抛弃
2. ability əˈbɪləti 能力；才能
3. abstract ˈæbstrækt 抽象的；摘要

也支持标准 JSON / CSV 格式''',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),

            // 操作按钮行
            Row(
              children: [
                // AI 清洗按钮
                Expanded(
                  flex: 2,
                  child: _buildAiCleanButton(),
                ),
                const SizedBox(width: 8),
                // 传统解析按钮
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _onParse,
                    icon: const Icon(Icons.preview, size: 18),
                    label: const Text('预览解析'),
                  ),
                ),
              ],
            ),

            // AI 清洗状态提示
            if (_aiStatusMessage != null) _buildAiStatusCard(),

            // 传统解析结果
            if (_detectedFormat != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('识别格式：${_detectedFormat!.toUpperCase()}',
                    style: TextStyle(
                        color: colors.inkSoft, fontSize: 12)),
              ),
            if (_parsedCount > 0 && _aiStatus == AiCleanStatus.idle)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('解析到 $_parsedCount 词',
                    style: TextStyle(
                        color: colors.mintDeep, fontSize: 12)),
              ),

            // AI 清洗结果预览
            if (_aiCleanedWords.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildAiCleanedPreview(),
              const SizedBox(height: 12),
              // 确认导入按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _onConfirmAiImport,
                  icon: const Icon(Icons.check_circle, size: 22),
                  label: Text('确认导入 ${_aiCleanedWords.length} 词',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ] else if (_detectedFormat != null && _parsedCount > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _onConfirmImport,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('确认导入'),
                ),
              ),
            ],

            // 错误提示
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildMessageCard(
                  icon: Icons.error_outline,
                  color: AppColors.error,
                  message: _error!,
                ),
              ),
            // 成功提示
            if (_success != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildMessageCard(
                  icon: Icons.check_circle,
                  color: AppColors.success,
                  message: _success!,
                ),
              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AI 清洗按钮（渐变风格）
  Widget _buildAiCleanButton() {
    final colors = context.appColors;
    final isLoading = _aiStatus == AiCleanStatus.loading;
    return SizedBox(
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : LinearGradient(
                  colors: [colors.mintDeep, colors.mintDeep],
                ),
          color: isLoading ? Colors.grey[300] : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : _onAiClean,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.grey),
                )
              : const Icon(Icons.auto_fix_high, size: 18, color: Colors.white),
          label: Text(
            isLoading ? '清洗中…' : 'AI 清洗',
            style: TextStyle(
              color: isLoading ? Colors.grey[600] : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  /// AI 清洗状态卡片
  Widget _buildAiStatusCard() {
    final colors = context.appColors;
    Color color;
    IconData icon;
    switch (_aiStatus) {
      case AiCleanStatus.loading:
        color = colors.mintDeep;
        icon = Icons.hourglass_top;
        break;
      case AiCleanStatus.success:
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case AiCleanStatus.fallback:
        color = AppColors.accentOrange;
        icon = Icons.info;
        break;
      case AiCleanStatus.error:
        color = AppColors.error;
        icon = Icons.error;
        break;
      default:
        color = colors.mintDeep;
        icon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _buildMessageCard(
        icon: icon,
        color: color,
        message: _aiStatusMessage ?? '',
      ),
    );
  }

  /// AI 清洗结果预览列表
  Widget _buildAiCleanedPreview() {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('清洗结果预览',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${_aiCleanedWords.length} 词',
                style: TextStyle(
                    fontSize: 12, color: colors.inkSoft)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: colors.mintDeep.withValues(alpha: 0.15)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                _aiCleanedWords.length > 20 ? 20 : _aiCleanedWords.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final w = _aiCleanedWords[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // 序号
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colors.mintDeep.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                              fontSize: 11,
                              color: colors.mintDeep,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 单词
                    Text(
                      w.word,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (w.phonetic != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        w.phonetic!,
                        style: TextStyle(
                            fontSize: 11, color: colors.inkSoft),
                      ),
                    ],
                    const Spacer(),
                    // 释义
                    Expanded(
                      child: Text(
                        w.definition.join('；'),
                        style: TextStyle(
                            fontSize: 13, color: colors.inkSoft),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_aiCleanedWords.length > 20)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                '…还有 ${_aiCleanedWords.length - 20} 个词条',
                style: TextStyle(
                    fontSize: 12, color: colors.inkSoft),
              ),
            ),
          ),
      ],
    );
  }

  /// 通用消息卡片
  Widget _buildMessageCard({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
