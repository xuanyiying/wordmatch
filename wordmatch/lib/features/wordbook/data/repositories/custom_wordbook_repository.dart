import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';
import 'package:wordmatch/features/wordbook/data/services/custom_wordbook_importer.dart';

/// 持久化的自定义词库文件
class CustomWordbookFile {
  final String bookId;
  final String name;
  final List<Word> words;
  final DateTime importedAt;

  const CustomWordbookFile({
    required this.bookId,
    required this.name,
    required this.words,
    required this.importedAt,
  });
}

/// 自定义词库仓库：负责把 ImportResult 写入磁盘 / 列出 / 删除 / 加载
class CustomWordbookRepository {
  static const String _folder = 'custom_wordbooks';

  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _folder));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 把导入结果落盘，返回生成的 CustomWordbookFile
  Future<CustomWordbookFile> save({
    required String name,
    required List<ImportedWord> words,
  }) async {
    final dir = await _dir();
    // 时间戳 + 随机后缀，避免快速连续导入时同毫秒碰撞覆盖
    final bookId =
        'custom_${DateTime.now().millisecondsSinceEpoch}_${_randomSuffix()}';
    final file = File(p.join(dir.path, '$bookId.json'));
    final data = {
      'book_id': bookId,
      'name': name,
      'imported_at': DateTime.now().toIso8601String(),
      'words': words.map((w) => w.toJson()).toList(),
    };
    await file.writeAsString(json.encode(data), flush: true);
    return _toFile(bookId, data);
  }

  /// 列出所有自定义词库
  Future<List<CustomWordbookFile>> list() async {
    final dir = await _dir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();
    final result = <CustomWordbookFile>[];
    for (final f in files) {
      try {
        final raw = json.decode(await f.readAsString()) as Map<String, dynamic>;
        result.add(_toFile(_idFromPath(f.path), raw));
      } catch (_) {
        // 损坏的文件跳过
      }
    }
    result.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    return result;
  }

  /// 加载某个自定义词库的 Word 列表
  Future<List<Word>?> loadWords(String bookId) async {
    final safeId = _sanitizeBookId(bookId);
    if (safeId == null) return null;
    final dir = await _dir();
    final file = File(p.join(dir.path, '$safeId.json'));
    if (!file.existsSync()) return null;
    try {
      final raw =
          json.decode(await file.readAsString()) as Map<String, dynamic>;
      return (raw['words'] as List)
          .map((e) => Word(
                id: '${raw['book_id']}_${(e as Map)['word']}',
                word: e['word'] as String,
                definition: (e['definition'] as List).cast<String>(),
                bookId: raw['book_id'] as String,
                phoneticUs: e['phonetic'] as String?,
                phoneticUk: e['phonetic'] as String?,
              ))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// 删除某个自定义词库
  Future<bool> remove(String bookId) async {
    final safeId = _sanitizeBookId(bookId);
    if (safeId == null) return false;
    final dir = await _dir();
    final file = File(p.join(dir.path, '$safeId.json'));
    if (!file.existsSync()) return false;
    await file.delete();
    return true;
  }

  // ============ helpers ============
  /// 校验并规范化 bookId，仅允许字母数字下划线。
  /// 防止恶意 bookId（含 `../` 等路径分隔符）造成目录穿越。
  static String? _sanitizeBookId(String bookId) {
    if (bookId.isEmpty) return null;
    final trimmed = bookId.trim();
    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(trimmed)) return null;
    return trimmed;
  }

  static String _randomSuffix() {
    final n = DateTime.now().microsecondsSinceEpoch % 100000;
    return '$n';
  }

  static String _idFromPath(String path) {
    final base = p.basenameWithoutExtension(path);
    return base;
  }

  static CustomWordbookFile _toFile(String bookId, Map<String, dynamic> raw) {
    final name = (raw['name'] as String?) ?? bookId;
    final importedAt = DateTime.tryParse(raw['imported_at'] as String? ?? '') ??
        DateTime.now();
    final words = (raw['words'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((m) {
          // 逐条容错：损坏的词条（缺 word/definition 类型错误）跳过，避免整库加载失败
          final word = m['word'];
          if (word is! String || word.trim().isEmpty) return null;
          final defs = _extractDefinitions(m['definition']);
          if (defs.isEmpty) return null;
          return Word(
            // 与 loadWords 的 id 生成规则保持一致（bookId_word）
            id: '${bookId}_$word',
            word: word,
            definition: defs,
            bookId: bookId,
            phoneticUs: m['phonetic'] as String?,
            phoneticUk: m['phonetic'] as String?,
          );
        })
        .whereType<Word>()
        .toList();
    return CustomWordbookFile(
      bookId: bookId,
      name: name,
      words: words,
      importedAt: importedAt,
    );
  }

  /// 从可能的 List / String / null 中提取释义字符串列表
  static List<String> _extractDefinitions(Object? defs) {
    if (defs is List) {
      return defs
          .map((d) => d.toString().trim())
          .where((d) => d.isNotEmpty)
          .toList();
    }
    if (defs is String) {
      return defs
          .split(RegExp(r'[;；,，]'))
          .map((d) => d.trim())
          .where((d) => d.isNotEmpty)
          .toList();
    }
    return [];
  }
}
