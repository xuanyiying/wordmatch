import 'dart:convert';
import 'dart:developer';
import 'package:wordmatch/core/network/http_client.dart';

/// AI 请求异常
class AiClientException implements Exception {
  final String message;

  const AiClientException(this.message);

  @override
  String toString() => 'AiClientException: $message';
}

/// API 格式类型
enum AiApiFormat {
  /// 阿里云 DashScope 专有格式
  dashscope,

  /// OpenAI 兼容格式（DeepSeek、Moonshot、OpenAI 等）
  openAiCompatible,
}

/// 统一 AI 客户端
///
/// 封装 DashScope / OpenAI-compatible API 的请求、配置读取、响应解析与错误降级。
/// 所有 AI 功能应通过此类发起请求，避免各自维护 HTTP 与配置逻辑。
class AiClient {
  AiClient._();

  /// 大模型 API 地址（可配置）
  static String apiUrl = 'https://api.deepseek.com/chat/completions';

  /// 大模型 API Key（需用户配置）
  static String apiKey = '';

  /// 默认模型
  static String model = 'deepseek-chat';

  /// 是否启用思考模式（DeepSeek：请求体携带 `thinking` + `reasoning_effort`）。
  /// 思考模式下 `temperature` 等采样参数不生效，请求体会省略该参数。
  static bool thinkingEnabled = true;

  /// 默认超时时间（毫秒）
  static const int defaultTimeoutMs = 15000;

  /// 是否已配置 API Key
  static bool get isConfigured => apiKey.isNotEmpty;

  /// 根据 URL 自动判断 API 格式
  ///
  /// DashScope URL 通常包含 "dashscope"，其余视为 OpenAI 兼容格式。
  static AiApiFormat get _apiFormat {
    final url = apiUrl.toLowerCase();
    if (url.contains('dashscope')) return AiApiFormat.dashscope;
    return AiApiFormat.openAiCompatible;
  }

  /// 配置 API 参数
  static void configure({
    required String key,
    String? url,
    String? modelName,
  }) {
    apiKey = key;
    if (url != null && url.isNotEmpty) apiUrl = url;
    if (modelName != null && modelName.isNotEmpty) model = modelName;
  }

  /// 向大模型发送消息并返回解析后的 JSON result
  ///
  /// [messages] 为对话消息列表，每条包含 `role` 与 `content`。
  /// [timeoutMs] 可覆盖默认超时。
  /// [useThinking] 是否开启思考模式。短输出任务（助记/例句/词汇网络等）应传
  /// `false`，思考模式会显著增加延迟与隐藏 token 成本，仅对长文/复杂推理值得开启。
  /// 返回 AI 响应中 `result` 字段对应的 Map；失败时抛出 [AiClientException]。
  static Future<Map<String, dynamic>?> postChat(
    List<Map<String, String>> messages, {
    int timeoutMs = defaultTimeoutMs,
    double temperature = 0.1,
    int maxTokens = 2000,
    bool useThinking = false,
  }) async {
    final content = await _send(
      messages,
      timeoutMs: timeoutMs,
      temperature: temperature,
      maxTokens: maxTokens,
      useThinking: useThinking,
    );
    return extractResult(content);
  }

  /// 测试连接：发送最小消息并返回模型原始回复文本。
  ///
  /// 与 [postChat] 不同，本方法不要求 JSON `result` 格式，
  /// 任何非空文本回复均视为连接成功；失败时抛出 [AiClientException]。
  static Future<String> testConnection({
    int timeoutMs = 10000,
    int maxTokens = 512,
  }) async {
    return _send(
      [
        {'role': 'system', 'content': '你是助手'},
        {'role': 'user', 'content': '请只回复 ok 这 2 个字母，不要加任何标点或换行'},
      ],
      timeoutMs: timeoutMs,
      maxTokens: maxTokens,
    );
  }

  /// 发送消息并返回模型原始回复文本（不解析 JSON `result`）。
  ///
  /// 已校验：返回内容非空，否则抛 [AiClientException]。
  static Future<String> _send(
    List<Map<String, String>> messages, {
    int timeoutMs = defaultTimeoutMs,
    double temperature = 0.1,
    int maxTokens = 2000,
    bool useThinking = false,
  }) async {
    if (apiKey.isEmpty) {
      throw const AiClientException('未配置 API Key');
    }

    try {
      final format = _apiFormat;
      final requestBody = format == AiApiFormat.dashscope
          ? _buildDashScopeBody(messages, temperature, maxTokens)
          : _buildOpenAiBody(
              messages,
              temperature,
              maxTokens,
              useThinking: useThinking,
            );

      final response = await appHttpClient
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(milliseconds: timeoutMs));

      if (response.statusCode != 200) {
        // 尝试从响应体提取错误信息
        String detail = '';
        try {
          final errBody = json.decode(response.body) as Map<String, dynamic>;
          final errMsg = errBody['error'];
          if (errMsg is Map) {
            detail = errMsg['message']?.toString() ?? '';
          } else if (errMsg is String) {
            detail = errMsg;
          }
        } catch (_) {}
        final suffix = detail.isNotEmpty ? ': $detail' : '';
        throw AiClientException(
          'AI 服务返回错误 (${response.statusCode})$suffix',
        );
      }

      final responseBody = json.decode(response.body) as Map<String, dynamic>;
      final content = _extractContent(responseBody, format);
      if (content == null || content.isEmpty) {
        throw const AiClientException('AI 返回内容为空');
      }

      return content;
    } on AiClientException {
      rethrow;
    } catch (e) {
      log('AiClient request failed: $e');
      throw AiClientException('AI 请求失败：$e');
    }
  }

  /// 构建 DashScope 专有请求体
  static Map<String, dynamic> _buildDashScopeBody(
    List<Map<String, String>> messages,
    double temperature,
    int maxTokens,
  ) {
    return {
      'model': model,
      'input': {'messages': messages},
      'parameters': {
        'result_format': 'message',
        'temperature': temperature,
        'max_tokens': maxTokens,
      },
    };
  }

  /// 构建 OpenAI 兼容请求体（DeepSeek / Moonshot / OpenAI 等）
  ///
  /// 思考模式由 [useThinking] 与全局开关 [thinkingEnabled] 共同决定（二者为与关系）。
  /// 仅当两者都为 true 才开启，便于短输出任务显式关闭以省成本降延迟。
  static Map<String, dynamic> _buildOpenAiBody(
    List<Map<String, String>> messages,
    double temperature,
    int maxTokens, {
    bool useThinking = false,
  }) {
    final body = <String, dynamic>{
      'model': model,
      'messages': messages,
    };
    if (thinkingEnabled && useThinking) {
      // DeepSeek 思考模式（参考 https://api-docs.deepseek.com/zh-cn/guides/thinking_mode）：
      //   - thinking.type=enabled 显式开启思考模式
      //   - reasoning_effort 控制思考强度（low/medium 会映射为 high，默认 high）
      //   - 思考模式下 temperature/top_p 等采样参数不生效，故省略不发送
      body['thinking'] = {'type': 'enabled'};
      body['reasoning_effort'] = 'high';
      body['max_tokens'] = maxTokens;
    } else {
      body['temperature'] = temperature;
      body['max_tokens'] = maxTokens;
    }
    return body;
  }

  /// 从响应体中提取 AI 回复文本，兼容两种 API 格式
  static String? _extractContent(
    Map<String, dynamic> responseBody,
    AiApiFormat format,
  ) {
    final List<dynamic>? choices;

    if (format == AiApiFormat.dashscope) {
      // DashScope: responseBody.output.choices[0].message.content
      final output = responseBody['output'] as Map<String, dynamic>?;
      choices = output?['choices'] as List<dynamic>?;
    } else {
      // OpenAI-compatible: responseBody.choices[0].message.content
      choices = responseBody['choices'] as List<dynamic>?;
    }

    if (choices == null || choices.isEmpty) {
      throw const AiClientException('AI 未返回内容');
    }

    final message = choices[0]['message'] as Map<String, dynamic>?;
    return message?['content'] as String?;
  }

  /// 从 AI 返回文本中提取 JSON 的 `result` 字段
  ///
  /// 1. 先尝试从 markdown code block 中提取 JSON
  /// 2. 再尝试直接解析整个文本
  /// 3. 返回 `result` 字段对应的 Map，解析失败返回 null
  static Map<String, dynamic>? extractResult(String content) {
    String jsonStr = content.trim();

    final codeBlockMatch =
        RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```').firstMatch(content);
    if (codeBlockMatch != null) {
      jsonStr = codeBlockMatch.group(1)!.trim();
    }

    try {
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      final result = decoded['result'] as Map<String, dynamic>?;
      return result;
    } catch (e) {
      log('AiClient failed to parse JSON: $e, content: $content');
      return null;
    }
  }

  /// 简单包装：发送 system + user 两条消息并返回 result
  ///
  /// [useThinking] 默认 false——大多数 AI 学习功能（助记/例句/词汇网络/对话）输出短、
  /// 无需复杂推理，关闭思考模式可省成本、降延迟。仅在词串烧等长文任务按需开启。
  static Future<Map<String, dynamic>?> complete({
    required String system,
    required String user,
    int timeoutMs = defaultTimeoutMs,
    double temperature = 0.1,
    int maxTokens = 2000,
    bool useThinking = false,
  }) async {
    return postChat(
      [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      timeoutMs: timeoutMs,
      temperature: temperature,
      maxTokens: maxTokens,
      useThinking: useThinking,
    );
  }
}
