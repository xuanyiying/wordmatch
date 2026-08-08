import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordmatch/core/constants/app_colors.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/settings/secure_storage_service.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/ai/data/models/ai_provider.dart';
import 'package:wordmatch/features/ai/data/services/ai_client.dart';
import 'package:wordmatch/features/ai/data/services/ai_response_cache.dart';
import 'package:wordmatch/features/wordbook/data/services/ai_clean_service.dart';

/// AI 设置 Key（API Key 由 [SecureStorageService] 加密存储，此处仅存 URL/模型名）
const _kApiUrl = 'ai_api_url';
const _kModelName = 'ai_model_name';

/// 自定义选项的标识值
const _kCustomProvider = '__custom__';
const _kCustomModel = '__custom_model__';

/// AI 配置二级页面：大模型 API 配置、使用说明、语料缓存、保存/清除/测试
class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiUrlController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  bool _isObscure = true;
  bool _isLoaded = false;

  /// 当前选中的提供商 key（provider name 或 __custom__）
  String _selectedProvider = _kCustomProvider;

  /// 当前选中的模型下拉选项（模型名 或 __custom_model__）
  String? _selectedModelOption;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = await SecureStorageService.readApiKey();
      // ⚠️ 兜底：SharedPreferences 可能保存过空字符串（不是 null），
      // 空字符串同样视为「未设置」，回退到 AiCleanService 默认值，
      // 这样才能命中预设提供商下拉，不用用户手动填地址。
      final rawSavedUrl = prefs.getString(_kApiUrl);
      final rawSavedModel = prefs.getString(_kModelName);
      final savedUrl =
          (rawSavedUrl != null && rawSavedUrl.isNotEmpty)
              ? rawSavedUrl
              : AiCleanService.apiUrl;
      final savedModel =
          (rawSavedModel != null && rawSavedModel.isNotEmpty)
              ? rawSavedModel
              : AiCleanService.model;

      _apiKeyController.text = savedKey;
      _apiUrlController.text = savedUrl;
      _modelController.text = savedModel;

      // 1. 根据 URL 反查预设提供商
      final matched = AiProvider.findByUrl(savedUrl);
      if (matched != null) {
        _selectedProvider = matched.name;
      } else if (savedKey.isEmpty &&
          rawSavedUrl == null &&
          rawSavedModel == null) {
        // 2. 全新安装 / 从未保存过任何配置：默认选中首个预设（DeepSeek）
        _selectedProvider = AiProvider.presets.first.name;
      } else {
        // 3. 保存过自定义的旧数据或未知 URL → 保持自定义模式
        _selectedProvider = _kCustomProvider;
      }

      AiCleanService.configure(
        savedKey,
        url: savedUrl,
        modelName: savedModel,
      );
      _initSelectedModelOption();
    } catch (e, st) {
      // 兜底：任何异常都不能让页面停在加载转圈状态，
      // 回退到自定义模式并保持默认值可用。
      debugPrint('[AiSettingsScreen] _loadSettings 失败: $e\n$st');
      _selectedProvider = _kCustomProvider;
      _selectedModelOption = null;
    } finally {
      if (mounted) setState(() => _isLoaded = true);
    }
  }

  /// 初始化模型下拉选择状态
  void _initSelectedModelOption() {
    if (_selectedProvider != _kCustomProvider) {
      // 预设可能因版本迭代被移除，用 orElse 兜底，避免 firstWhere 抛异常
      final provider = AiProvider.presets.firstWhere(
        (p) => p.name == _selectedProvider,
        orElse: () => AiProvider.presets.first,
      );
      if (provider.models.isNotEmpty) {
        _selectedModelOption = provider.models.contains(_modelController.text)
            ? _modelController.text
            : _kCustomModel;
      } else {
        _selectedModelOption = null;
      }
    } else {
      _selectedModelOption = null;
    }
  }

  /// 选择提供商时自动填充 URL 和默认模型
  void _onProviderChanged(String? value) {
    if (value == null) return;
    setState(() => _selectedProvider = value);

    if (value == _kCustomProvider) {
      setState(() => _selectedModelOption = null);
      return;
    }

    final provider = AiProvider.presets.firstWhere((p) => p.name == value);
    _apiUrlController.text = provider.apiUrl;
    if (provider.defaultModel.isNotEmpty) {
      _modelController.text = provider.defaultModel;
    }

    setState(() {
      _selectedModelOption = provider.models.isNotEmpty
          ? (provider.models.contains(provider.defaultModel)
              ? provider.defaultModel
              : provider.models.first)
          : null;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = _apiKeyController.text.trim();
    final apiUrl = _apiUrlController.text.trim();
    final modelName = _modelController.text.trim();

    // API Key 使用系统级加密存储（Keystore/Keychain），避免明文落盘
    await SecureStorageService.writeApiKey(apiKey);
    // 兼容旧版本明文存储，清除历史明文 Key
    await prefs.remove('ai_api_key');
    if (apiUrl.isNotEmpty) {
      await prefs.setString(_kApiUrl, apiUrl);
    }
    if (modelName.isNotEmpty) {
      await prefs.setString(_kModelName, modelName);
    } else {
      await prefs.remove(_kModelName);
    }

    AiCleanService.configure(
      apiKey,
      url: apiUrl.isNotEmpty ? apiUrl : null,
      modelName: modelName.isNotEmpty ? modelName : null,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(apiKey.isNotEmpty ? 'AI 配置已保存' : 'AI 配置已清除'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('清除 AI 配置？'),
        content: const Text('将删除已保存的 API Key 和 API 地址，AI 清洗功能将不可用。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _apiKeyController.clear();
      final first = AiProvider.presets.first;
      _apiUrlController.text = first.apiUrl;
      _modelController.text = first.defaultModel;
      _selectedProvider = first.name;
      _initSelectedModelOption();
      await _saveSettings();
    }
  }

  /// 测试 AI 连接
  Future<void> _testConnection() async {
    final key = _apiKeyController.text.trim();
    final url = _apiUrlController.text.trim();
    final model = _modelController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('请先填 API Key'), backgroundColor: AppColors.error));
      return;
    }
    AiCleanService.configure(key,
        url: url.isNotEmpty ? url : null,
        modelName: model.isNotEmpty ? model : null);
    AiClient.configure(
        key: key,
        url: url.isNotEmpty ? url : null,
        modelName: model.isNotEmpty ? model : null);
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const AlertDialog(
                content: Row(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(width: 12),
              Text('测试连接中...')
            ])));
    try {
      await AiClient.testConnection(timeoutMs: 10000, maxTokens: 512);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ 连接成功！模型响应正常'),
          backgroundColor: AppColors.success));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ 连接失败：$e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: !_isLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.pagePaddingH,
                        24,
                        AppSizes.pagePaddingH,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAiConfigCard(),
                          const SizedBox(height: 14),
                          _buildActionButtons(),
                          const SizedBox(height: 16),
                          _buildHelpCard(),
                          const SizedBox(height: 16),
                          _buildCacheCard(),
                        ],
                      ),
                    ),
            ),
          ],
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
        gradient: colors.headerGradient,
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 设置',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  '配置大模型 API，启用 AI 清洗功能',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 字段小标题
  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  /// 统一输入框装饰
  InputDecoration _inputDecoration({IconData? icon, String? hint}) {
    return InputDecoration(
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: context.appColors.inkSoft)
          : null,
      hintText: hint,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  /// AI 配置卡片
  Widget _buildAiConfigCard() {
    final isConfigured = AiCleanService.isConfigured;
    final isCustom = _selectedProvider == _kCustomProvider;
    final currentPreset = _selectedProvider != _kCustomProvider
        ? AiProvider.presets
            .where((p) => p.name == _selectedProvider)
            .firstOrNull
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.appColors.mintDeep.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行 + 状态标签
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: context.appColors.headerGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('大模型 API 配置',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.ink)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConfigured
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.accentOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isConfigured ? '已配置' : '未配置',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isConfigured
                        ? AppColors.success
                        : AppColors.accentOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 服务商 ──
          _buildFieldLabel('服务商'),
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedProvider),
            initialValue: _selectedProvider,
            decoration: _inputDecoration(
              icon: currentPreset != null
                  ? Icons.cloud_outlined
                  : Icons.edit_note_rounded,
            ),
            items: [
              const DropdownMenuItem(
                  value: _kCustomProvider, child: Text('自定义')),
              ...AiProvider.presets.map((p) =>
                  DropdownMenuItem(value: p.name, child: Text(p.name))),
            ],
            onChanged: _onProviderChanged,
          ),
          const SizedBox(height: 16),

          // ── API Key ──
          _buildFieldLabel('API Key'),
          TextField(
            controller: _apiKeyController,
            obscureText: _isObscure,
            decoration: InputDecoration(
              hintText: '输入 ${currentPreset?.name ?? '服务商'} 的 API Key',
              isDense: true,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentPreset != null &&
                      currentPreset.website.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('前往 ${currentPreset.website} 申请 Key'),
                          duration: const Duration(seconds: 3),
                        ));
                      },
                      icon: Icon(Icons.open_in_new_rounded,
                          size: 18, color: context.appColors.mintDeep),
                      tooltip: '前往 ${currentPreset.name} 官网申请',
                    ),
                  IconButton(
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                    icon: Icon(
                        _isObscure ? Icons.visibility_off : Icons.visibility,
                        size: 20),
                  ),
                ],
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),

          // ── API 地址（仅自定义模式显示，预设模式由服务商自动决定）──
          if (isCustom) ...[
            _buildFieldLabel('API 地址'),
            TextField(
              controller: _apiUrlController,
              style: const TextStyle(fontSize: 12),
              decoration: _inputDecoration(
                  hint: '输入 OpenAI 兼容格式的 API 地址'),
            ),
            const SizedBox(height: 16),
          ],

          // ── 模型 ──
          _buildFieldLabel('模型'),
          if (isCustom) ...[
            // 自定义提供商：直接输入模型名
            TextField(
              controller: _modelController,
              decoration: _inputDecoration(hint: '输入模型名称'),
            ),
          ] else ...[
            // 预设提供商：下拉选择 + 自定义模型名
            DropdownButtonFormField<String>(
              key: ValueKey(
                  '${_selectedProvider}_${_selectedModelOption ?? ''}'),
              initialValue: _selectedModelOption,
              decoration: _inputDecoration(icon: Icons.psychology_outlined),
              items: [
                ...(currentPreset?.models ?? const []).map((m) =>
                    DropdownMenuItem(
                        value: m,
                        child: Text(m, style: const TextStyle(fontSize: 13)))),
                const DropdownMenuItem(
                  value: _kCustomModel,
                  child: Text('自定义模型名', style: TextStyle(fontSize: 13)),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedModelOption = value);
                if (value != null && value != _kCustomModel) {
                  setState(() => _modelController.text = value);
                }
              },
            ),
            if (_selectedModelOption == _kCustomModel) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _modelController,
                decoration: _inputDecoration(
                  hint: currentPreset?.defaultModel.isNotEmpty == true
                      ? '默认：${currentPreset!.defaultModel}'
                      : '输入模型名称',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// 操作按钮：保存（主）+ 测试连接；清除配置作为次要入口
  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF3A6C28), context.appColors.mintDeep]),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save_rounded,
                        color: Colors.white, size: 20),
                    label: const Text('保存配置',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
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
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed:
                      AiCleanService.isConfigured ? _clearSettings : null,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('清除'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _testConnection,
            icon: const Icon(Icons.network_check_rounded, size: 20),
            label: const Text('测试连接',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              foregroundColor: context.appColors.mintDeep,
              backgroundColor: context.appColors.mintDeep.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide(
                  color: context.appColors.mintDeep.withValues(alpha: 0.3)),
            ),
          ),
        ),
      ],
    );
  }

  /// 使用说明卡片（精简版）
  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.mintDeep.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: context.appColors.mintDeep.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded,
                  size: 20, color: context.appColors.mintDeep),
              const SizedBox(width: 8),
              Text('使用说明',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.mintDeep)),
            ],
          ),
          const SizedBox(height: 10),
          _buildHelpStep('1', '选择服务商，前往对应平台申请 API Key'),
          _buildHelpStep('2', '填入 API Key，选择模型，点击保存'),
          _buildHelpStep('3', '保存后在单词详情页使用 AI 助记 / 例句 / 词网 / 对话练习'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: AppColors.accentOrange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '未配置 API Key 时，AI 功能将自动降级到本地基础词库',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.accentOrange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: context.appColors.mintDeep.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.appColors.mintDeep)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13, color: context.appColors.ink))),
        ],
      ),
    );
  }

  /// AI 缓存管理卡片：显示条目数/体积、支持按类型/全部清理
  Widget _buildCacheCard() {
    return FutureBuilder<AiCacheStats>(
      future: AiResponseCache.stats(),
      builder: (context, snap) {
        final stats = snap.data;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storage_outlined,
                      size: 20, color: context.appColors.mintDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI 语料缓存',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.mintDeep,
                      ),
                    ),
                  ),
                  if (stats != null)
                    Text(
                      '${stats.totalCount} 条 · ${AiCacheStats.formatBytes(stats.totalBytes)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              if (stats != null && stats.hitRate != null)
                Text(
                  '本次启动命中率 ${(stats.hitRate! * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              const SizedBox(height: 12),
              if (stats != null && stats.byTypeCount.isNotEmpty) ...[
                ...AiCacheStats.typeLabels.entries
                    .where((e) => (stats.byTypeCount[e.key] ?? 0) > 0)
                    .map((e) => _buildCacheTypeTile(stats, e.key, e.value)),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _confirmClearAll(context);
                        setState(() {});
                      },
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('清空全部'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCacheTypeTile(AiCacheStats stats, String type, String label) {
    final count = stats.byTypeCount[type] ?? 0;
    final bytes = stats.byTypeBytes[type] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('· $label', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$count 条 · ${AiCacheStats.formatBytes(bytes)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const Spacer(),
          TextButton(
            onPressed: () async {
              final n = await AiResponseCache.clearByType(type);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已删除 $n 条 $label 缓存')),
                );
                setState(() {});
              }
            },
            child: const Text('删除', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空全部 AI 缓存？'),
        content: const Text('删除后下次访问会重新调用 AI 接口生成语料，产生 API 调用费用。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final n = await AiResponseCache.clearAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已删除 $n 条 AI 缓存')),
    );
  }
}
