import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wordmatch/core/settings/learner_profile.dart';
import 'package:wordmatch/core/subscription/subscription_service.dart';
import 'package:wordmatch/features/ai/data/services/ai_client.dart';

import '../../domain/services/annotation_models.dart';

/// AI 语境语义标注服务（标注决策核心）
///
/// 把文章段落批量交给 LLM 做语境语意分析：
/// - 一词多义取本句语境义项
/// - 识别影响理解的动词短语/习语并整体标注
/// - 排除编程术语、专有名词与超常用功能词
///
/// 结果按文章持久缓存（文章静态不会失效），二次打开零成本零延迟。
/// AI 未配置/超限/失败时返回 null，阅读页静默降级到本地初稿。
class SemanticAnnotatorService {
  SemanticAnnotatorService._();

  static const int _timeoutMs = 30000;
  static const int _maxTokens = 3000;

  /// 单次请求的正文字符上限：整篇文章按此预算切成多个请求，
  /// 保证长文章的每一段都能被 AI 分析到（而不是只分析前半截）。
  static const int _maxChunkChars = 4000;

  /// 单段超长时截断发送（否则整段会被跳过，该段完全没有 AI 标注）
  static const int _maxSingleParaChars = 4000;

  /// 系统提示词按学习者身份参数化（身份来自「我的身份」设置，默认国内开发者）
  static String _systemFor(String identity) =>
      '你是中国英语学习者的英文阅读助教。当前学习者画像：$identity。'
      '你的任务是结合语境语意，'
      '从英文段落中挑出真正妨碍该学习者理解的生词和短语。'
      '规则：'
      '① 一词多义时必须结合本句语境取义项，不要给通用罗列；'
      '② 识别影响理解的动词短语、习语、搭配并整体标注（如 look forward to、figure out）；'
      '③ 排除编程/技术术语（React、API、Docker、SQL 等）、人名地名等专有名词、'
      'the/of/and 这类超常用功能词，以及 about/accept/access/company/run/figure '
      '这类读者必然认识的高频基础词（只有在该词本句义项本身就很生僻时才可标注）；'
      '④ 输入可能附带 candidates 数组（与 paragraphs 按段对齐的本地预筛候选词）：'
      '对其中每个候选逐一判断，需要标注的以原文实际词形输出（不要改写词形，'
      '原文是 tests 就输出 tests），不需要的不要输出；'
      '⑤ 每段最多 8 个，宁缺勿滥，确实没有生词就返回空数组；'
      '⑥ gloss 用简短中文（不超过 12 字）；'
      '⑦ 严格只输出 JSON，格式为'
      ' {"result": {"paragraphs": [{"p": 段落序号, "items": [{"t": "原文表面形式", "g": "中文语境义", "phrase": 是否短语}]}]}}';

  /// 分析文章（带缓存）。
  ///
  /// [sourceId]/[articleId] 用于缓存键；[paragraphs] 为阅读页提取的
  /// prose 段落纯文本列表（顺序即渲染顺序）；[learnerHint] 可显式覆盖
  /// 学习者画像，缺省取「我的身份」设置（默认国内开发者）。
  /// [candidates]：与 [paragraphs] 对齐的每段本地预筛候选词（来自
  /// LocalAnnotationEngine.aiCandidates）。传 null 表示未预筛（全部段落
  /// 送 AI）；传了则**空候选段直接跳过请求**（本地本就不会标任何词），
  /// 非空候选随请求注入提示词，供 AI 逐词判断、减少漏判。
  /// 返回 null 表示本次无 AI 结果（未配置/超限/失败），调用方保留本地初稿。
  static Future<SemanticResult?> analyzeArticle({
    required String sourceId,
    required String articleId,
    required List<String> paragraphs,
    List<List<String>>? candidates,
    String? learnerHint,
  }) async {
    // 0. 读取学习者身份（缓存键含身份：换身份后旧标注自动失效）
    final identity = learnerHint ?? await LearnerProfile.load();

    // 1. 缓存命中直接返回（含"AI 分析过但没有生词"的结果，避免重复请求）
    final cached = await _loadCache(sourceId, articleId, identity);
    if (cached != null) return cached;

    if (!AiClient.isConfigured) return null;

    // 2. AI 额度控制（与词库清洗/学习服务等共用同一额度池）
    final allowed = await SubscriptionService.consumeAiQuota();
    if (!allowed) return null;

    // 3. 整篇文章按字符预算切成多个请求顺序分析，合并各块结果；
    //    AI 返回的段落序号是相对本次提交数组的下标，需加块起始偏移。
    //    零候选段在切块时跳过（不发请求），本地标注自然兜底。
    final chunks = _planChunks(paragraphs, candidates);
    if (chunks.isEmpty) {
      // 全部段落都被预筛跳过：合法空结果，无需请求也不落缓存
      return const SemanticResult([]);
    }

    final started = DateTime.now();
    final merged = <ParagraphAnnotation>[];
    var failedChunks = 0;
    try {
      for (final chunk in chunks) {
        final user = json.encode({
          'learner': identity,
          'paragraphs': chunk.texts,
          if (chunk.candidates.isNotEmpty) 'candidates': chunk.candidates,
        });

        final result = await AiClient.complete(
          system: _systemFor(identity),
          user: user,
          timeoutMs: _timeoutMs,
          maxTokens: _maxTokens,
          temperature: 0.2,
        );
        if (result == null) {
          failedChunks++;
          continue;
        }
        final part = SemanticResult.fromJson(result);
        for (final p in part.paragraphs) {
          merged.add(ParagraphAnnotation(
            paragraphIndex: p.paragraphIndex + chunk.start,
            tokens: p.tokens,
          ));
        }
      }

      final elapsed = DateTime.now().difference(started).inMilliseconds;
      if (merged.isEmpty && failedChunks > 0) {
        log('SemanticAnnotator: AI 返回无法解析（${elapsed}ms）');
        return null;
      }
      final semantic = SemanticResult(merged);
      log('SemanticAnnotator: 分析完成 ${elapsed}ms，${chunks.length} 块，'
          '${semantic.paragraphs.length} 段命中'
          '${failedChunks > 0 ? '，$failedChunks 块失败（不缓存以便重试）' : ''}');
      // 全部块成功才落缓存（空结果是合法结果，同样缓存避免重试）；
      // 部分失败时本次用合并结果渲染，下次打开重试缺块
      if (failedChunks == 0) {
        await _saveCache(sourceId, articleId, identity, semantic);
      }
      return semantic;
    } catch (e) {
      log('SemanticAnnotator: 分析失败 $e');
      return null; // 静默降级
    }
  }

  /// 把段落列表按 [_maxChunkChars] 字符预算切成多块。
  /// 每块记录起始段落号（全局下标）与实际发送文本及对应候选词；
  /// 单段超长则截断；[candidates] 非空时空候选段整段跳过。
  @visibleForTesting
  static List<({int start, List<String> texts, List<List<String>> candidates})>
      planChunksForTest(
              List<String> paragraphs,
              [List<List<String>>? candidates]) =>
          _planChunks(paragraphs, candidates);

  static List<({int start, List<String> texts, List<List<String>> candidates})>
      _planChunks(List<String> paragraphs, List<List<String>>? candidates) {
    final chunks =
        <({int start, List<String> texts, List<List<String>> candidates})>[];
    var current = <String>[];
    var currentCandidates = <List<String>>[];
    var currentStart = 0;
    var total = 0;

    void flush() {
      if (current.isNotEmpty) {
        chunks.add((
          start: currentStart,
          texts: current,
          candidates: currentCandidates,
        ));
        current = <String>[];
        currentCandidates = <List<String>>[];
        total = 0;
      }
    }

    for (var i = 0; i < paragraphs.length; i++) {
      // 预筛判定过零候选的段落：本地不会标注任何词，跳过 AI 请求
      if (candidates != null && candidates[i].isEmpty) continue;
      final para = paragraphs[i].length > _maxSingleParaChars
          ? paragraphs[i].substring(0, _maxSingleParaChars)
          : paragraphs[i];
      if (current.isEmpty) {
        currentStart = i;
        current = [para];
        if (candidates != null) currentCandidates = [candidates[i]];
        total = para.length;
      } else if (total + para.length <= _maxChunkChars) {
        current.add(para);
        if (candidates != null) currentCandidates.add(candidates[i]);
        total += para.length;
      } else {
        flush();
        currentStart = i;
        current = [para];
        if (candidates != null) currentCandidates = [candidates[i]];
        total = para.length;
      }
    }
    flush();
    return chunks;
  }

  // ============ 文件缓存 ============

  static Future<Directory?> _cacheDir() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'annotation_cache'));
      if (!dir.existsSync()) await dir.create(recursive: true);
      return dir;
    } catch (_) {
      return null;
    }
  }

  /// 缓存键 = 版本_来源_文章_身份标签（LearnerProfile.tagOf 为跨运行稳定哈希，
  /// 换身份后自然取到新键，旧画像的标注不会误命中）。
  /// 段落提取逻辑变化（新增列表项/引用段落）会改变段落序号，提示词选词
  /// 口径收紧（排除高频基础词）也必须提升 [_cacheVersion]，否则会读到
  /// 旧口径的标注/错配到别的段落。
  /// v4：整篇文章分块分析（v3 只分析前 6000 字符，长文后半段缺标注）。
  /// v5：本地候选词注入提示词 + 零候选段跳过请求 + AI 未选中的词书词
  /// 保留本地标注（合并语义变更），旧口径结果全部作废。
  /// 只截断前缀控制文件名长度，身份标签必须完整保留（截断会导致哈希碰撞）。
  static const _cacheVersion = 'v5';

  static String _cacheKey(String sourceId, String articleId, String identity) {
    final prefix =
        '${_cacheVersion}_${sourceId}_${articleId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}';
    final clipped =
        prefix.substring(0, prefix.length.clamp(0, 130)); // 130+1+8 < 140
    return '${clipped}_${LearnerProfile.tagOf(identity)}';
  }

  /// 仅供测试：暴露缓存键计算，验证「换身份 → 缓存失效」
  @visibleForTesting
  static String cacheKeyForTest(
          String sourceId, String articleId, String identity) =>
      _cacheKey(sourceId, articleId, identity);

  static Future<SemanticResult?> _loadCache(
      String sourceId, String articleId, String identity) async {
    final dir = await _cacheDir();
    if (dir == null) return null;
    final file =
        File(p.join(dir.path, '${_cacheKey(sourceId, articleId, identity)}.json'));
    if (!file.existsSync()) return null;
    try {
      final raw = json.decode(await file.readAsString()) as Map<String, dynamic>;
      return SemanticResult.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveCache(String sourceId, String articleId,
      String identity, SemanticResult result) async {
    final dir = await _cacheDir();
    if (dir == null) return;
    try {
      final file = File(p.join(
          dir.path, '${_cacheKey(sourceId, articleId, identity)}.json'));
      await file.writeAsString(json.encode(result.toJson()), flush: true);
    } catch (_) {
      // 缓存写失败不影响主流程
    }
  }

  // ============ 批量语境释义（本地标注的生词 + 所在句 → AI） ============
  //
  // 段落语义分析每段最多 8 词且受正文长度上限，覆盖不到的本地标注词
  // 若回退词典首义会脱离语境（如 run a company 显示"跑"）。此处把
  // 全部待释义词连同所在句批量送 AI，保证每个展示的括注都贴合语境。

  /// 单次请求携带的词数上限。
  static const int _glossBatchSize = 25;

  static const String _glossSystem = '你是英语阅读助教。用户给出若干英语单词'
      '及其在文章中的所在句子，请为每个单词给出该句语境下最贴切的简短中文释义。'
      '规则：'
      '① 只给贴合该语境的一个义项，不要罗列多个；'
      '② 中文不超过 12 字，可在开头加词性缩写（如 v. / n. / adj.）；'
      '③ 严格只输出 JSON，格式为'
      ' {"result": {"glosses": [{"t": "单词", "g": "中文语境义"}]}}，'
      '不要任何解释文字或 markdown 代码块。';

  /// 为 [items]（word + 所在句）批量获取语境释义，返回 word(小写) → gloss。
  ///
  /// 文章级文件缓存：已释义的词不重复请求；AI 未配置/额度不足时返回已缓存
  /// 部分；单批失败静默跳过，不影响其余批次。
  static Future<Map<String, String>> glossWords({
    required String sourceId,
    required String articleId,
    required List<({String word, String sentence})> items,
  }) async {
    if (items.isEmpty) return const {};

    // 去重（同词多段落只保留首句），先取缓存
    final deduped = <String, String>{};
    for (final it in items) {
      deduped.putIfAbsent(it.word.toLowerCase(), () => it.sentence);
    }
    final cached = await _loadGlossCache(sourceId, articleId);
    final missing = <({String word, String sentence})>[
      for (final e in deduped.entries)
        if (!cached.containsKey(e.key)) (word: e.key, sentence: e.value),
    ];
    if (missing.isEmpty || !AiClient.isConfigured) return cached;

    final allowed = await SubscriptionService.consumeAiQuota();
    if (!allowed) return cached;

    final fetched = <String, String>{};
    for (var i = 0; i < missing.length; i += _glossBatchSize) {
      final end = i + _glossBatchSize > missing.length
          ? missing.length
          : i + _glossBatchSize;
      final chunk = missing.sublist(i, end);
      try {
        final result = await AiClient.complete(
          system: _glossSystem,
          user: json.encode({
            'words': [
              for (final c in chunk) {'word': c.word, 'sentence': c.sentence},
            ],
          }),
          timeoutMs: _timeoutMs,
          maxTokens: 1600,
          temperature: 0.2,
        );
        if (result != null) {
          fetched.addAll(parseGlossResult(
              result, chunk.map((c) => c.word).toSet()));
        }
      } catch (_) {
        // 单批失败静默跳过
      }
    }

    if (fetched.isNotEmpty) {
      final merged = {...cached, ...fetched};
      await _saveGlossCache(sourceId, articleId, merged);
      return merged;
    }
    return cached;
  }

  /// 把弹卡按需 AI 查词得到的语境义写回文章 gloss 缓存：
  /// 下次长按同一词 / 行内括注直接命中，不再重复请求 AI。
  static Future<void> saveGloss({
    required String sourceId,
    required String articleId,
    required String word,
    required String gloss,
  }) async {
    final key = word.toLowerCase().trim();
    final value = gloss.trim();
    if (key.isEmpty || value.isEmpty) return;
    final cached = await _loadGlossCache(sourceId, articleId);
    if (cached[key] == value) return;
    await _saveGlossCache(sourceId, articleId, {...cached, key: value});
  }

  /// 解析 glosses 结果：只收请求词表内、非空且 ≤14 字的释义。
  @visibleForTesting
  static Map<String, String> parseGlossResult(
      Map<String, dynamic> result, Set<String> allowed) {
    final list = result['glosses'];
    if (list is! List) return const {};
    final out = <String, String>{};
    for (final e in list) {
      if (e is! Map) continue;
      final w = (e['t'] as String?)?.toLowerCase().trim() ?? '';
      final g = (e['g'] as String?)?.trim() ?? '';
      if (w.isEmpty || g.isEmpty || g.length > 14 || !allowed.contains(w)) {
        continue;
      }
      out[w] = g;
    }
    return out;
  }

  /// 语境释义缓存键（不依赖学习者身份：同一文章的词义与画像无关）。
  static String _glossCacheKey(String sourceId, String articleId) {
    final prefix = 'gloss_${sourceId}_'
        '${articleId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}';
    return prefix.substring(0, prefix.length.clamp(0, 130));
  }

  static Future<Map<String, String>> _loadGlossCache(
      String sourceId, String articleId) async {
    final dir = await _cacheDir();
    if (dir == null) return const {};
    final file =
        File(p.join(dir.path, '${_glossCacheKey(sourceId, articleId)}.json'));
    if (!file.existsSync()) return const {};
    try {
      final raw = json.decode(await file.readAsString()) as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return const {};
    }
  }

  static Future<void> _saveGlossCache(String sourceId, String articleId,
      Map<String, String> glosses) async {
    final dir = await _cacheDir();
    if (dir == null) return;
    try {
      final file =
          File(p.join(dir.path, '${_glossCacheKey(sourceId, articleId)}.json'));
      await file.writeAsString(json.encode(glosses), flush: true);
    } catch (_) {
      // 缓存写失败不影响主流程
    }
  }
}
