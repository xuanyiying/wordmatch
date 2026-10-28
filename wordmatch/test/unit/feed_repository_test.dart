import 'package:flutter_test/flutter_test.dart';
import 'package:wordmatch/features/feed/data/datasources/feed_disk_cache.dart';
import 'package:wordmatch/features/feed/data/repositories/feed_repository.dart';
import 'package:wordmatch/features/feed/data/services/devto_service.dart';
import 'package:wordmatch/features/feed/domain/models/feed_models.dart';

/// 可控的 dev.to 数据源：按需返回结果或抛错
class _FakeDevTo extends DevToService {
  _FakeDevTo({this.items = const [], this.error});

  final List<FeedItem> items;
  final Object? error;

  @override
  Future<List<FeedItem>> fetchFeed({int page = 1}) async {
    if (error != null) throw error!;
    return items;
  }
}

/// 内存版磁盘缓存：不触碰文件系统
class _FakeDiskCache extends FeedDiskCache {
  final Map<String, FeedResult> entries = {};

  @override
  Future<FeedResult?> read(String key) async => entries[key];

  @override
  void write(String key, List<FeedItem> items) {
    entries[key] = FeedResult(
      items: items,
      isStale: true,
      updatedAt: DateTime(2026, 1, 1),
    );
  }
}

FeedItem _item(String id) => FeedItem(
      id: id,
      source: FeedSource.devto,
      title: '标题 $id',
      excerpt: '摘要 $id',
      author: 'author',
      publishedAt: '2026-01-01',
      url: 'https://example.com/$id',
      coverImage: 'https://example.com/$id.png',
      extra: const {'tag': 'webdev'},
    );

void main() {
  group('FeedItem 序列化', () {
    test('toJson/fromJson 往返后字段一致', () {
      final original = _item('abc');
      final restored = FeedItem.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.source, original.source);
      expect(restored.title, original.title);
      expect(restored.excerpt, original.excerpt);
      expect(restored.author, original.author);
      expect(restored.publishedAt, original.publishedAt);
      expect(restored.url, original.url);
      expect(restored.coverImage, original.coverImage);
      expect(restored.extra, original.extra);
    });

    test('字段缺失时回退默认值而不是抛错', () {
      final restored = FeedItem.fromJson(const {});
      expect(restored.id, '');
      expect(restored.title, '');
      expect(restored.extra, isEmpty);
      expect(restored.source, FeedSource.devto);
    });
  });

  group('FeedRepository 离线兜底', () {
    test('网络正常时返回最新内容并写入磁盘缓存', () async {
      final disk = _FakeDiskCache();
      final repo = FeedRepository(
        devToService: _FakeDevTo(items: [_item('a'), _item('b')]),
        diskCache: disk,
      );

      final result = await repo.getFeed(FeedSource.devto);

      expect(result.isStale, isFalse);
      expect(result.items.length, 2);
      expect(disk.entries.containsKey('devto'), isTrue);
    });

    test('网络失败且存在磁盘缓存时回退到缓存内容', () async {
      final disk = _FakeDiskCache();
      disk.entries['devto'] = FeedResult(
        items: [_item('cached')],
        isStale: true,
        updatedAt: DateTime(2026, 1, 1),
      );
      final repo = FeedRepository(
        devToService: _FakeDevTo(error: Exception('网络不可用')),
        diskCache: disk,
      );

      final result = await repo.getFeed(FeedSource.devto);

      expect(result.isStale, isTrue);
      expect(result.items.single.id, 'cached');
      expect(result.updatedAt, DateTime(2026, 1, 1));
    });

    test('网络失败且无磁盘缓存时抛出原异常', () async {
      final repo = FeedRepository(
        devToService: _FakeDevTo(error: Exception('网络不可用')),
        diskCache: _FakeDiskCache(),
      );

      expect(
        () => repo.getFeed(FeedSource.devto),
        throwsA(isA<Exception>()),
      );
    });
  });
}
