import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';

/// 本地词库数据源：从 assets 加载 JSON 词库
class LocalWordDatasource {
  /// 加载指定词库的 JSON 数据
  Future<List<Word>> loadBook(String bookId) async {
    if (bookId.startsWith('custom_')) {
      // 自定义词库走 CustomWordbookRepository
      return [];
    }
    final assetPath = _getAssetPath(bookId);
    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonStr) as Map<String, dynamic>;
      final wordsList = jsonData['words'] as List<dynamic>;
      return wordsList
          .map((e) => Word.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // 词库不存在时返回空列表
      return [];
    }
  }

  /// 获取词库资源路径
  String _getAssetPath(String bookId) {
    switch (bookId) {
      case 'gaokao':
        return 'assets/data/words_gaokao.json';
      case 'cet4':
        return 'assets/data/words_cet4.json';
      case 'cet6':
        return 'assets/data/words_cet6.json';
      case 'kaoyan':
        return 'assets/data/words_kaoyan.json';
      case 'it':
        return 'assets/data/words_it.json';
      default:
        return 'assets/data/words_gaokao.json';
    }
  }

  /// 获取可用的词库列表（不含自定义词库）
  List<BookInfo> getAvailableBooks() {
    return [
      const BookInfo(
          id: 'gaokao', name: '高考词汇', wordCount: 3500, available: true),
      const BookInfo(
          id: 'cet4', name: '四级词汇', wordCount: 4542, available: true),
      const BookInfo(
          id: 'cet6', name: '六级词汇', wordCount: 3991, available: true),
      const BookInfo(
          id: 'kaoyan', name: '考研词汇', wordCount: 5047, available: true),
      const BookInfo(id: 'it', name: 'IT技术词汇', wordCount: 476, available: true),
    ];
  }
}

/// 词库信息
class BookInfo {
  final String id;
  final String name;
  final int wordCount;
  final bool available;
  final bool isCustom;

  const BookInfo({
    required this.id,
    required this.name,
    required this.wordCount,
    required this.available,
    this.isCustom = false,
  });
}
