import 'package:wordmatch/core/subscription/subscription_service.dart';
import 'package:wordmatch/features/ai/data/prompts/ai_prompts.dart';
import 'package:wordmatch/features/ai/data/services/ai_client.dart';
import 'package:wordmatch/features/ai/data/services/ai_response_cache.dart';

/// AI 每日学习报告服务
class AiReportService {
  AiReportService._();

  /// 生成每日学习报告
  ///
  /// 缓存键按日期生成，一天只生成一次。
  static Future<DailyAiReport?> generateDailyReport({
    required int completedNew,
    required int completedReview,
    required int wrongCount,
    required double accuracy,
    required List<String> wrongWords,
  }) async {
    final allowed = await SubscriptionService.consumeAiQuota();
    if (!allowed) {
      return null;
    }
    final now = DateTime.now();
    final dateKey = '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}';
    final cacheKey = 'daily_$dateKey';

    final cached = await AiResponseCache.get('report', cacheKey);
    if (cached != null) {
      return _parseReport(cached);
    }

    if (!AiClient.isConfigured) return null;

    try {
      final result = await AiClient.complete(
        system: AiPrompts.systemJsonExpert,
        user: AiPrompts.dailyReportPrompt(
          completedNew: completedNew,
          completedReview: completedReview,
          wrongCount: wrongCount,
          accuracy: accuracy,
          wrongWords: wrongWords,
        ),
        maxTokens: 800,
        useThinking: false,
      );
      if (result == null) return null;

      await AiResponseCache.set(
        'report',
        cacheKey,
        result,
        ttl: const Duration(days: 7),
      );
      return _parseReport(result);
    } catch (_) {
      return null;
    }
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');

  static DailyAiReport? _parseReport(Map<String, dynamic> data) {
    final encouragement = (data['encouragement'] as String?)?.trim();
    final weakPointsRaw = data['weakPoints'] as List<dynamic>?;
    final suggestionsRaw = data['suggestions'] as List<dynamic>?;

    if (encouragement == null || encouragement.isEmpty) return null;

    List<String> parseList(List<dynamic>? list) {
      if (list == null) return [];
      return list
          .map((item) => (item as String?)?.trim())
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toList();
    }

    return DailyAiReport(
      encouragement: encouragement,
      weakPoints: parseList(weakPointsRaw),
      suggestions: parseList(suggestionsRaw),
    );
  }
}

/// AI 每日报告数据
class DailyAiReport {
  final String encouragement;
  final List<String> weakPoints;
  final List<String> suggestions;

  const DailyAiReport({
    required this.encouragement,
    this.weakPoints = const [],
    this.suggestions = const [],
  });
}
