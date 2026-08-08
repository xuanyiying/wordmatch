import 'package:wordmatch/features/wordbook/data/datasources/local_word_datasource.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';
import 'package:wordmatch/features/wordbook/data/repositories/custom_wordbook_repository.dart';

/// 词库仓库：统一管理词库数据的加载与查询
class WordbookRepository {
  final LocalWordDatasource _localDatasource;
  final CustomWordbookRepository _customRepo;
  final Map<String, List<Word>> _cache = {};

  WordbookRepository({
    LocalWordDatasource? datasource,
    CustomWordbookRepository? customRepo,
  })  : _localDatasource = datasource ?? LocalWordDatasource(),
        _customRepo = customRepo ?? CustomWordbookRepository();

  /// 加载指定词库（优先缓存）
  Future<List<Word>> loadBook(String bookId) async {
    if (_cache.containsKey(bookId)) return _cache[bookId]!;
    List<Word> words;
    if (bookId.startsWith('custom_')) {
      words = (await _customRepo.loadWords(bookId)) ?? [];
    } else {
      words = await _localDatasource.loadBook(bookId);
    }
    _cache[bookId] = words;
    return words;
  }

  /// 获取随机 N 个单词（用于生成关卡）
  Future<List<Word>> getRandomWords(String bookId, int count) async {
    final all = await loadBook(bookId);
    final shuffled = List<Word>.from(all)..shuffle();
    return shuffled.take(count).toList();
  }

  /// 获取指定词频范围的单词
  Future<List<Word>> getWordsByFrequency(String bookId,
      {int minFreq = 1, int maxFreq = 5}) async {
    final all = await loadBook(bookId);
    return all
        .where((w) => w.frequency >= minFreq && w.frequency <= maxFreq)
        .toList();
  }

  /// 获取可用的词库列表（内置 + 自定义）
  Future<List<BookInfo>> getAvailableBooks() async {
    final builtIn = _localDatasource.getAvailableBooks();
    final customs = await _customRepo.list();
    final customInfos = customs
        .map((c) => BookInfo(
              id: c.bookId,
              name: c.name,
              wordCount: c.words.length,
              available: true,
              isCustom: true,
            ))
        .toList();
    return [...builtIn, ...customInfos];
  }

  /// 搜索单词（模糊匹配）
  Future<List<Word>> searchWords(String bookId, String query) async {
    final all = await loadBook(bookId);
    final lowerQuery = query.toLowerCase();
    return all
        .where((w) =>
            w.word.toLowerCase().contains(lowerQuery) ||
            w.definition.any((d) => d.contains(query)))
        .toList();
  }

  /// 清除缓存
  void clearCache() {
    _cache.clear();
  }

  /// 暴露自定义仓库（用于导入 UI / 删除）
  CustomWordbookRepository get customRepo => _customRepo;
}
