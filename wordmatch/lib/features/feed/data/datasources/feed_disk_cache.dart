import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';

/// 资讯列表的磁盘缓存
///
/// 目的：网络不可用时仍能看到上次抓取的资讯（离线可读），而不是一个空白错误页。
/// 存放在应用文档目录的单个 JSON 文件里，按「源|子键」分组。
class FeedDiskCache {
  static const String _fileName = 'feed_cache.json';

  /// 最多保留的缓存分组数（超出按抓取时间淘汰最旧的）
  static const int _maxKeys = 12;

  /// 单个分组最多保留的条目数
  static const int _maxItemsPerKey = 60;

  final Map<String, _Entry> _entries = {};
  bool _loaded = false;
  Future<void>? _loadFuture;

  /// 串行落盘队列：避免并发写同一个文件导致内容损坏
  Future<void> _writeQueue = Future<void>.value();

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loadFuture ??= _load();
    await _loadFuture;
  }

  Future<void> _load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      if (raw.isEmpty) return;
      final decoded = json.decode(raw);
      if (decoded is! Map) return;
      decoded.forEach((key, value) {
        if (value is! Map) return;
        final ts = value['ts'];
        final rawItems = value['items'];
        if (ts is! int || rawItems is! List) return;
        final items = <FeedItem>[];
        for (final item in rawItems) {
          if (item is! Map) continue;
          try {
            items.add(FeedItem.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {
            // 单条损坏不影响其余条目
          }
        }
        _entries[key] =
            _Entry(DateTime.fromMillisecondsSinceEpoch(ts), items);
      });
    } catch (e) {
      developer.log('FeedDiskCache: 读取缓存失败', error: e);
    } finally {
      _loaded = true;
    }
  }

  /// 读取某个分组的缓存内容；没有缓存返回 null
  Future<FeedResult?> read(String key) async {
    await _ensureLoaded();
    final entry = _entries[key];
    if (entry == null || entry.items.isEmpty) return null;
    return FeedResult(
      items: entry.items,
      isStale: true,
      updatedAt: entry.fetchedAt,
    );
  }

  /// 写入某个分组的缓存内容
  ///
  /// 落盘在后台串行执行，不阻塞调用方。
  void write(String key, List<FeedItem> items) {
    if (items.isEmpty) return;
    _writeQueue = _writeQueue.then((_) async {
      await _ensureLoaded();
      final trimmed = items.length > _maxItemsPerKey
          ? items.sublist(0, _maxItemsPerKey)
          : items;
      _entries[key] = _Entry(DateTime.now(), trimmed);

      // 分组过多时淘汰最旧的
      if (_entries.length > _maxKeys) {
        final sorted = _entries.entries.toList()
          ..sort((a, b) => a.value.fetchedAt.compareTo(b.value.fetchedAt));
        for (final stale in sorted.take(_entries.length - _maxKeys)) {
          _entries.remove(stale.key);
        }
      }

      await _save();
    });
  }

  /// 把缓存写入磁盘（失败只记日志，不影响主流程）
  Future<void> _save() async {
    try {
      final file = await _file();
      final payload = <String, dynamic>{
        for (final e in _entries.entries)
          e.key: {
            'ts': e.value.fetchedAt.millisecondsSinceEpoch,
            'items': e.value.items.map((i) => i.toJson()).toList(),
          },
      };
      await file.writeAsString(json.encode(payload), flush: true);
    } catch (e) {
      developer.log('FeedDiskCache: 写入缓存失败', error: e);
    }
  }

  Future<File> _file() async {
    final docs = await getApplicationDocumentsDirectory();
    return File(p.join(docs.path, _fileName));
  }
}

class _Entry {
  final DateTime fetchedAt;
  final List<FeedItem> items;

  const _Entry(this.fetchedAt, this.items);
}
