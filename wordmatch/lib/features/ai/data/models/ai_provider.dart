/// AI 服务提供商预设
class AiProvider {
  /// 显示名称
  final String name;

  /// Chat Completions API 地址
  final String apiUrl;

  /// 默认模型名
  final String defaultModel;

  /// API 格式（dashscope / openai）
  final String format;

  /// 可选模型列表
  final List<String> models;

  /// 官网地址（用于申请 API Key）
  final String website;

  const AiProvider({
    required this.name,
    required this.apiUrl,
    required this.defaultModel,
    required this.format,
    this.models = const [],
    this.website = '',
  });

  /// 预设提供商列表
  static const List<AiProvider> presets = [
    AiProvider(
      name: 'DeepSeek',
      apiUrl: 'https://api.deepseek.com/chat/completions',
      defaultModel: 'deepseek-v4-flash',
      format: 'openai',
      models: ['deepseek-v4-pro', 'deepseek-v4-flash'],
      website: 'https://platform.deepseek.com',
    ),
  ];

  /// 根据 API 地址查找匹配的预设提供商
  ///
  /// 匹配优先级：
  /// 1. URL 完全相等 → 直接命中
  /// 2. 包含提供商域名关键字（子串匹配）→ 命中
  ///    （便于用户使用代理镜像 URL 时仍能显示正确的下拉提供商）
  static AiProvider? findByUrl(String url) {
    if (url.isEmpty) return null;
    final lower = url.toLowerCase();
    AiProvider? fuzzy;
    for (final p in presets) {
      if (p.apiUrl == url) return p;
      if (fuzzy == null) {
        // 提取预设域名关键字（如 deepseek、dashscope、bigmodel 等）作模糊匹配
        final key = _domainKeyword(p.apiUrl);
        if (key.isNotEmpty && lower.contains(key)) {
          fuzzy = p;
        }
      }
    }
    return fuzzy;
  }

  /// 从 API URL 中提取「服务商标识关键字」（host 的核心部分，不含 www、com 等）
  static String _domainKeyword(String apiUrl) {
    try {
      final uri = Uri.parse(apiUrl);
      final host = uri.host.toLowerCase();
      // 去掉常见前缀和顶级域，保留主体：
      // e.g. api.deepseek.com → deepseek
      //      dashscope.aliyuncs.com → dashscope
      //      open.bigmodel.cn → bigmodel
      final parts = host.split('.')
        ..removeWhere((s) =>
            s.isEmpty ||
            s == 'www' ||
            s == 'api' ||
            s == 'com' ||
            s == 'cn' ||
            s == 'net' ||
            s == 'org' ||
            s == 'io' ||
            s == 'ai' ||
            s == 'cloud' ||
            s == 'aliyuncs' ||
            s == 'volces' ||
            s == 'bcebos' ||
            s == 'baidu' ||
            s == 'baidubce' ||
            s == 'tencent' ||
            s == 'console');
      return parts.isNotEmpty ? parts.first : '';
    } catch (_) {
      return '';
    }
  }
}
