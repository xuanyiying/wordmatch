import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart' show rootBundle;

/// 频序常用词表（阅读标注的常用词过滤）
///
/// 资产由 scripts/build_common_words.py 生成（Google 万亿词语料频序前 6000，
/// 或 ECDICT frq 排序），数组下标 + 1 即词频排名。
///
/// 用途：[LocalAnnotationEngine] 把排名 ≤ [commonRankThreshold] 的词视为
/// 学习者已掌握——即便它在当前词书里且没有学习进度，也不自动标注，
/// 避免 about/accept/access 这类基础词被满屏标红。用户显式「学习中」或
/// 已收藏的词不受此过滤影响。
class WordFrequencyService {
  WordFrequencyService._();

  static const String _assetPath = 'assets/dict/common_words.json';

  /// intermediate 档常用词阈值：对齐 BaiitMobile 1500~2000 取保守下沿。
  /// 阈值越小过滤越严，1000~2000 区间的词书词（industry、students 级）
  /// 仍会自动标注复现——词书词是学习目标，过滤过宽会漏掉该学的词。
  static const int commonRankThreshold = 1000;

  /// 密度超限时按生僻度择优需要的全量排名（仅加载一次）。
  static Map<String, int>? _ranks;
  static Set<String>? _common;
  static bool _loadFailed = false;

  /// 懒加载词表；公开供阅读页启动时预加载。
  static Future<void> ensureLoaded() async {
    if (_ranks != null || _loadFailed) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final list = (json.decode(raw) as List).cast<String>();
      _ranks = {
        for (var i = 0; i < list.length; i++) list[i].toLowerCase(): i + 1,
      };
      _common = {
        for (final e in _ranks!.entries)
          if (e.value <= commonRankThreshold) e.key,
      };
    } catch (_) {
      // 资产缺失：降级为不过滤（学习状态仍生效），不阻塞阅读
      _loadFailed = true;
      log('WordFrequencyService: 常用词表不可用，跳过常用词过滤');
    }
  }

  static bool get isAvailable => _ranks != null;

  /// 常用词集合（排名 ≤ [commonRankThreshold]），供标注引擎构造时注入。
  static Set<String> commonWords() => _common ?? const <String>{};

  /// 全量词 → 排名映射，供密度超限时按生僻度排序。
  static Map<String, int> ranks() => _ranks ?? const <String, int>{};
}
