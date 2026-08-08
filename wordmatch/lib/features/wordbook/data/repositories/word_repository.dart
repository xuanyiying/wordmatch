import 'package:wordmatch/features/wordbook/data/datasources/local_word_datasource.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';

/// 词库仓库：负责加载本地词库数据，建立全局 ID 索引
///
/// 提供按 ID 查找单词的能力，避免从 wordId 格式中猜单词。
class WordRepository {
  final LocalWordDatasource _datasource = LocalWordDatasource();
  List<Word>? _cachedWords;
  Map<String, Word>? _index;

  /// 加载所有内置词库（优先从缓存读取）
  ///
  /// 同时构建 wordId → Word 的索引表，供 findById 使用。
  Future<List<Word>> loadWords() async {
    if (_cachedWords != null) return _cachedWords!;

    final books = _datasource.getAvailableBooks().map((b) => b.id);
    final List<Word> all = [];
    for (final bookId in books) {
      final words = await _datasource.loadBook(bookId);
      all.addAll(words);
    }

    _cachedWords = all;
    _index = {for (final w in all) w.id: w};
    return _cachedWords!;
  }

  /// 确保缓存和索引已加载
  Future<void> _ensureLoaded() async {
    if (_cachedWords == null) await loadWords();
  }

  /// 按 ID 查找单词
  ///
  /// 找不到时返回 null。调用方可以结合自定义词库数据库继续查找。
  Future<Word?> findById(String wordId) async {
    await _ensureLoaded();
    return _index![wordId];
  }

  /// 按英文单词文本查找（忽略大小写精确匹配）
  ///
  /// 在已加载缓存中按 `word.word` 字段匹配，返回完整 `Word`（含音标/例句/词根）。
  /// 用于同反义词网络 chip 跳转浏览模式时，把 AI 返回的纯词文本映射回完整词条。
  /// 未命中返回 null，调用方需自行构造最小 Word 兜底。
  Future<Word?> findByWordText(String text) async {
    await _ensureLoaded();
    final lower = text.toLowerCase();
    for (final w in _cachedWords!) {
      if (w.word.toLowerCase() == lower) return w;
    }
    return null;
  }

  /// 同步按 ID 查找（要求之前已调用过 loadWords 或 findById）
  Word? findByIdSync(String wordId) {
    return _index?[wordId];
  }

  /// 获取 ID → 单词文本 的快速映射（不需要完整 Word 对象时用）
  Future<Map<String, String>> getWordTextIndex() async {
    await _ensureLoaded();
    return {for (final w in _cachedWords!) w.id: w.word};
  }

  /// 获取指定词库的单词
  Future<List<Word>> loadWordsByBook(String bookId) async {
    await _ensureLoaded();
    return _cachedWords!.where((w) => w.bookId == bookId).toList();
  }

  /// 获取随机 N 个单词（用于生成关卡）
  Future<List<Word>> getRandomWords(int count, {String? bookId}) async {
    final all =
        bookId != null ? await loadWordsByBook(bookId) : await loadWords();
    final copy = List<Word>.from(all);
    copy.shuffle();
    return copy.take(count).toList();
  }

  /// 清除缓存
  void clearCache() {
    _cachedWords = null;
    _index = null;
  }
}
