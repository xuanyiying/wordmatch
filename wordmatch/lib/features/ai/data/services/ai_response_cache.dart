import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AI 语料缓存：磁盘 + 内存双层，支持 TTL、启动预热、命中率/体积统计、按类型清理
///
/// 磁盘存储基于 SharedPreferences（无需新增依赖），内存层为 `Map<String, _CacheEntry>`
/// 避免每次 get() 都走 async I/O，显著降低重复调用延迟。
class AiResponseCache {
  AiResponseCache._();

  static const String _prefix = 'ai_cache_';

  /// 支持的缓存类型（用于按类型统计/清理）
  static const List<String> knownTypes = [
    'mnemonic',
    'examples',
    'network',
    'dialogue',
    'clean_wordbook',
  ];

  /// 内存缓存层（热路径不走磁盘）
  /// key 格式同 SharedPreferences：ai_cache_{type}_{id}
  static final Map<String, _CacheEntry> _mem = {};

  /// 预热是否完成
  static bool _preloaded = false;

  /// 命中统计（仅 debug 下更新，但结构始终存在）
  static final Map<String, int> _hits = {};
  static final Map<String, int> _misses = {};

  // ========== 内部工具 ==========

  static String key(String type, String id) => '$_prefix${type}_$id';

  static String _typeFromKey(String k) {
    // ai_cache_mnemonic_abandon_gaokao → mnemonic
    if (!k.startsWith(_prefix)) return '';
    final rest = k.substring(_prefix.length);
    final us = rest.indexOf('_');
    return us < 0 ? rest : rest.substring(0, us);
  }

  // ========== 启动预热 ==========

  /// 启动时一次性把所有 AI 缓存从磁盘加载到内存
  ///
  /// 预热是 O(N) 的同步遍历，对几千条缓存耗时 < 10ms。
  /// 建议在 main() 中 WidgetsFlutterBinding 之后调用。
  static Future<void> preload() async {
    if (_preloaded) return;
    final sw = Stopwatch()..start();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
      for (final k in keys) {
        final raw = prefs.getString(k);
        if (raw == null || raw.isEmpty) continue;
        try {
          final decoded = json.decode(raw) as Map<String, dynamic>;
          final expiresAt = DateTime.parse(decoded['expiresAt'] as String);
          if (DateTime.now().isAfter(expiresAt)) {
            // 过期的顺手清掉
            unawaited(prefs.remove(k));
            continue;
          }
          _mem[k] = _CacheEntry(
            data: decoded['data'] as Map<String, dynamic>,
            expiresAt: expiresAt,
            sizeOnDisk: raw.length,
          );
        } catch (_) {
          // 损坏条目，移除
          unawaited(prefs.remove(k));
        }
      }
    } catch (e) {
      debugPrint('AiResponseCache: preload failed: $e');
    } finally {
      _preloaded = true;
      sw.stop();
      debugPrint(
        'AiResponseCache: preloaded ${_mem.length} entries in ${sw.elapsedMilliseconds}ms',
      );
    }
  }

  // ========== 读写 ==========

  /// 读取缓存（先查内存，再查磁盘）
  static Future<Map<String, dynamic>?> get(String type, String id) async {
    final k = key(type, id);

    // 1. 内存命中
    final mem = _mem[k];
    if (mem != null) {
      if (DateTime.now().isAfter(mem.expiresAt)) {
        _mem.remove(k);
        unawaited(remove(type, id));
        _misses[type] = (_misses[type] ?? 0) + 1;
        return null;
      }
      _hits[type] = (_hits[type] ?? 0) + 1;
      return mem.data;
    }

    // 2. 磁盘回读（预热完成后一般不会走到这里）
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(k);
    if (raw == null || raw.isEmpty) {
      _misses[type] = (_misses[type] ?? 0) + 1;
      return null;
    }
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(decoded['expiresAt'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        await remove(type, id);
        _misses[type] = (_misses[type] ?? 0) + 1;
        return null;
      }
      final data = decoded['data'] as Map<String, dynamic>?;
      if (data != null) {
        _mem[k] = _CacheEntry(
          data: data,
          expiresAt: expiresAt,
          sizeOnDisk: raw.length,
        );
      }
      _hits[type] = (_hits[type] ?? 0) + 1;
      return data;
    } catch (e) {
      // 缓存条目损坏：移除后按未命中处理
      log('AiResponseCache: 缓存条目损坏已移除 ($type/$id)', error: e);
      await remove(type, id);
      _misses[type] = (_misses[type] ?? 0) + 1;
      return null;
    }
  }

  /// 写入缓存（内存 + 磁盘双写）
  static Future<void> set(
    String type,
    String id,
    Map<String, dynamic> data, {
    Duration ttl = const Duration(days: 30),
  }) async {
    final k = key(type, id);
    final expiresAt = DateTime.now().add(ttl);
    final payload = <String, dynamic>{
      'data': data,
      'expiresAt': expiresAt.toIso8601String(),
    };
    final raw = json.encode(payload);

    _mem[k] = _CacheEntry(
      data: data,
      expiresAt: expiresAt,
      sizeOnDisk: raw.length,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(k, raw);
    } catch (e) {
      debugPrint('AiResponseCache: set failed ($type/$id): $e');
      // 磁盘写失败不抛异常，内存层仍可在本次启动内生效
    }
  }

  /// 删除指定缓存
  static Future<void> remove(String type, String id) async {
    final k = key(type, id);
    _mem.remove(k);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(k);
    } catch (_) {}
  }

  // ========== 按类型清理 ==========

  /// 删除某一类型的全部缓存（如 "examples"）
  static Future<int> clearByType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = key(type, ''); // ai_cache_{type}_
    final keys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final k in keys) {
      _mem.remove(k);
      await prefs.remove(k);
    }
    debugPrint('AiResponseCache: cleared ${keys.length} entries of type=$type');
    return keys.length;
  }

  /// 清空全部 AI 缓存
  static Future<int> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    _mem.clear();
    _hits.clear();
    _misses.clear();
    debugPrint('AiResponseCache: cleared all ${keys.length} entries');
    return keys.length;
  }

  // ========== 统计 ==========

  /// 缓存统计：按类型条目数、总字节
  static Future<AiCacheStats> stats() async {
    final counts = <String, int>{};
    final sizes = <String, int>{};
    int totalCount = 0;
    int totalBytes = 0;

    // 优先用内存缓存（预热后和磁盘一致），否则读磁盘
    if (_preloaded) {
      _mem.forEach((k, v) {
        final t = _typeFromKey(k);
        counts[t] = (counts[t] ?? 0) + 1;
        sizes[t] = (sizes[t] ?? 0) + v.sizeOnDisk;
        totalCount++;
        totalBytes += v.sizeOnDisk;
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
      for (final k in keys) {
        final raw = prefs.getString(k);
        final t = _typeFromKey(k);
        counts[t] = (counts[t] ?? 0) + 1;
        sizes[t] = (sizes[t] ?? 0) + (raw?.length ?? 0);
        totalCount++;
        totalBytes += (raw?.length ?? 0);
      }
    }

    return AiCacheStats(
      byTypeCount: Map.unmodifiable(counts),
      byTypeBytes: Map.unmodifiable(sizes),
      totalCount: totalCount,
      totalBytes: totalBytes,
      hits: Map.unmodifiable(_hits),
      misses: Map.unmodifiable(_misses),
    );
  }
}

/// 内存缓存条目
class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime expiresAt;
  final int sizeOnDisk;

  _CacheEntry({
    required this.data,
    required this.expiresAt,
    required this.sizeOnDisk,
  });
}

/// 缓存统计快照（用于设置页显示）
class AiCacheStats {
  final Map<String, int> byTypeCount;
  final Map<String, int> byTypeBytes;
  final int totalCount;
  final int totalBytes;
  final Map<String, int> hits;
  final Map<String, int> misses;

  const AiCacheStats({
    required this.byTypeCount,
    required this.byTypeBytes,
    required this.totalCount,
    required this.totalBytes,
    required this.hits,
    required this.misses,
  });

  /// 字节数 → 人类可读（B/KB/MB）
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
  }

  /// 命中率 0~1，无访问时返回 null
  double? get hitRate {
    final total = _sumMap(hits) + _sumMap(misses);
    if (total == 0) return null;
    return _sumMap(hits) / total;
  }

  int _sumMap(Map<String, int> m) =>
      m.values.fold<int>(0, (a, b) => a + b);

  static const typeLabels = {
    'mnemonic': '助记',
    'examples': '例句',
    'network': '同反义词',
    'dialogue': '口语对话',
    'clean_wordbook': '词库清洗',
  };
}
