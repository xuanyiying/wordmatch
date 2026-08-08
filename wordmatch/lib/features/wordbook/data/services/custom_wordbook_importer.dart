import 'dart:convert';

/// 自定义词库导入器：解析 JSON / CSV 文本为可写入磁盘的词库结构
class CustomWordbookImportResult {
  final String name;
  final List<ImportedWord> words;
  final String? error;

  const CustomWordbookImportResult._({
    required this.name,
    required this.words,
    this.error,
  });

  bool get isSuccess => error == null;

  factory CustomWordbookImportResult.success({
    required String name,
    required List<ImportedWord> words,
  }) =>
      CustomWordbookImportResult._(name: name, words: words);

  factory CustomWordbookImportResult.failure(String message) =>
      CustomWordbookImportResult._(name: '', words: const [], error: message);
}

/// 单条导入的单词
class ImportedWord {
  final String word;
  final String? phonetic;
  final List<String> definition;

  const ImportedWord({
    required this.word,
    required this.definition,
    this.phonetic,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'phonetic': phonetic,
        'definition': definition,
      };
}

class CustomWordbookImporter {
  CustomWordbookImporter._();

  /// 词库最少需要 4 个词
  static const int minWords = 4;

  /// 根据文件名后缀判断格式
  static String? detectFormat(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.json')) return 'json';
    if (lower.endsWith('.csv')) return 'csv';
    return null;
  }

  /// 解析入口
  /// [name] 可选词库名称，CSV 模式下作为词库名使用；JSON 模式下忽略此参数，使用文件内 name 字段
  static CustomWordbookImportResult parse(String content, String format,
      {String? name}) {
    try {
      if (format == 'json') return _parseJson(content);
      if (format == 'csv') return _parseCsv(content, name: name);
      return CustomWordbookImportResult.failure('不支持的文件格式：$format');
    } on FormatException catch (e) {
      return CustomWordbookImportResult.failure('解析失败：${e.message}');
    } catch (e) {
      return CustomWordbookImportResult.failure('解析异常：$e');
    }
  }

  // ============ JSON ============
  static CustomWordbookImportResult _parseJson(String content) {
    final dynamic raw = json.decode(content);
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('JSON 根节点必须是对象');
    }
    final name = (raw['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      throw const FormatException('缺少 name 字段');
    }
    final wordsRaw = raw['words'];
    if (wordsRaw is! List) {
      throw const FormatException('缺少 words 数组');
    }
    final words = <ImportedWord>[];
    final seen = <String>{};
    for (var i = 0; i < wordsRaw.length; i++) {
      final w = wordsRaw[i];
      if (w is! Map<String, dynamic>) {
        throw FormatException('第 ${i + 1} 条必须是对象');
      }
      final word = (w['word'] as String?)?.trim();
      if (word == null || word.isEmpty) {
        throw FormatException('第 ${i + 1} 条缺少 word 字段');
      }
      if (seen.contains(word.toLowerCase())) {
        continue; // 去重
      }
      final defs = w['definition'];
      List<String> defsList;
      if (defs is List) {
        defsList = defs
            .map((d) => d.toString().trim())
            .where((d) => d.isNotEmpty)
            .toList();
      } else if (defs is String) {
        defsList = defs
            .split(RegExp(r'[;,；，]'))
            .map((d) => d.trim())
            .where((d) => d.isNotEmpty)
            .toList();
      } else {
        throw FormatException('第 ${i + 1} 条 definition 字段格式错误');
      }
      if (defsList.isEmpty) {
        throw FormatException('第 ${i + 1} 条 definition 不能为空');
      }
      seen.add(word.toLowerCase());
      words.add(ImportedWord(
        word: word,
        phonetic: (w['phonetic'] as String?)?.trim(),
        definition: defsList,
      ));
    }
    if (words.length < minWords) {
      return CustomWordbookImportResult.failure(
          '词条数 ${words.length} 不足（最少 $minWords 个）');
    }
    return CustomWordbookImportResult.success(name: name, words: words);
  }

  // ============ CSV ============
  static CustomWordbookImportResult _parseCsv(String content, {String? name}) {
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) throw const FormatException('文件为空');
    // 去除 UTF-8 BOM
    final header = lines.first.replaceFirst('\uFEFF', '');
    final cols =
        _splitCsvLine(header).map((c) => c.trim().toLowerCase()).toList();
    if (!cols.contains('word') || !cols.contains('definition')) {
      throw const FormatException('CSV 首行表头必须包含 word,definition（可选 phonetic）');
    }
    final wordIdx = cols.indexOf('word');
    final defIdx = cols.indexOf('definition');
    final phIdx = cols.indexOf('phonetic');
    final words = <ImportedWord>[];
    final seen = <String>{};
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cells = _splitCsvLine(line);
      if (cells.length < cols.length) {
        throw FormatException(
            '第 ${i + 1} 行列数不足（实际 ${cells.length}，需要 ${cols.length}）');
      }
      final word = cells[wordIdx].trim();
      if (word.isEmpty) throw FormatException('第 ${i + 1} 行 word 为空');
      if (seen.contains(word.toLowerCase())) continue;
      final defs = cells[defIdx]
          .split(RegExp(r'[;,；，]'))
          .map((d) => d.trim())
          .where((d) => d.isNotEmpty)
          .toList();
      if (defs.isEmpty) throw FormatException('第 ${i + 1} 行 definition 为空');
      seen.add(word.toLowerCase());
      words.add(ImportedWord(
        word: word,
        phonetic:
            phIdx >= 0 && phIdx < cells.length ? cells[phIdx].trim() : null,
        definition: defs,
      ));
    }
    if (words.length < minWords) {
      return CustomWordbookImportResult.failure(
          '词条数 ${words.length} 不足（最少 $minWords 个）');
    }
    // CSV 模式使用传入的名称，未传入时使用默认名
    final wordbookName =
        (name != null && name.trim().isNotEmpty) ? name.trim() : '导入词库';
    return CustomWordbookImportResult.success(name: wordbookName, words: words);
  }

  /// 简单 CSV 行分割（支持双引号包裹）
  static List<String> _splitCsvLine(String line) {
    final cells = <String>[];
    final buffer = StringBuffer();
    var inQuote = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        if (inQuote && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuote = !inQuote;
        }
      } else if (c == ',' && !inQuote) {
        cells.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(c);
      }
    }
    cells.add(buffer.toString());
    return cells;
  }
}
