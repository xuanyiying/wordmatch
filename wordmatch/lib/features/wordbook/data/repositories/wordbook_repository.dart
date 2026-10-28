import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordmatch/features/wordbook/data/datasources/local_word_datasource.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';
import 'package:wordmatch/features/wordbook/data/repositories/custom_wordbook_repository.dart';

/// 词库仓库：统一管理词库数据的加载与查询
class WordbookRepository {
  static const _hiddenBuiltinBooksKey = 'hidden_builtin_books';

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

  /// 获取可用的词库列表（内置 + 自定义），已删除（隐藏）的内置词库不返回
  Future<List<BookInfo>> getAvailableBooks() async {
    final hidden = await _getHiddenBuiltinBooks();
    final builtIn = _localDatasource
        .getAvailableBooks()
        .where((b) => !hidden.contains(b.id))
        .toList();
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

  /// 删除词库：自定义词库删除文件；内置词库通过黑名单隐藏
  Future<void> removeBook(String bookId) async {
    if (bookId.startsWith('custom_')) {
      await _customRepo.remove(bookId);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final hidden = await _getHiddenBuiltinBooks()..add(bookId);
    await prefs.setStringList(_hiddenBuiltinBooksKey, hidden.toList());
    _cache.remove(bookId);
  }

  /// 恢复已删除（隐藏）的内置词库
  Future<void> restoreBook(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = await _getHiddenBuiltinBooks()..remove(bookId);
    await prefs.setStringList(_hiddenBuiltinBooksKey, hidden.toList());
  }

  /// 读取已删除（隐藏）的内置词库列表
  Future<List<BookInfo>> getRemovedBuiltinBooks() async {
    final hidden = await _getHiddenBuiltinBooks();
    if (hidden.isEmpty) return const [];
    return _localDatasource
        .getAvailableBooks()
        .where((b) => hidden.contains(b.id))
        .toList();
  }

  /// 读取已隐藏的内置词库 ID 集合
  Future<Set<String>> _getHiddenBuiltinBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_hiddenBuiltinBooksKey) ?? const [];
      return list.toSet();
    } catch (_) {
      return <String>{};
    }
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
