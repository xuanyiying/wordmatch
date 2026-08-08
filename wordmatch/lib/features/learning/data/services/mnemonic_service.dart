import 'dart:convert';
import 'package:flutter/services.dart';

/// 单条助记数据
class Mnemonic {
  final String wordId;
  final String type; // story, homophone, association
  final String content;

  const Mnemonic({
    required this.wordId,
    required this.type,
    required this.content,
  });

  factory Mnemonic.fromJson(Map<String, dynamic> json) => Mnemonic(
        wordId: json['wordId'] as String,
        type: json['type'] as String,
        content: json['content'] as String,
      );

  /// 类型标签
  String get typeLabel {
    switch (type) {
      case 'story':
        return '联想故事';
      case 'homophone':
        return '谐音助记';
      case 'association':
        return '关联记忆';
      default:
        return '助记';
    }
  }

  /// 类型图标
  String get typeIcon {
    switch (type) {
      case 'story':
        return '📖';
      case 'homophone':
        return '🔊';
      case 'association':
        return '🔗';
      default:
        return '💡';
    }
  }
}

/// AI 助记服务：从本地 JSON 加载预计算的助记数据
class MnemonicService {
  MnemonicService._();

  /// 助记数据缓存：wordId → Mnemonic
  static Map<String, Mnemonic>? _cache;

  /// 已加载的词库 ID 列表
  static final Set<String> _loadedBooks = {};

  /// 加载指定词库的助记数据
  static Future<void> loadBook(String bookId) async {
    if (_loadedBooks.contains(bookId)) return;

    final assetPath = _getAssetPath(bookId);
    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonStr) as Map<String, dynamic>;
      final mnemonicsList = jsonData['mnemonics'] as List<dynamic>;

      _cache ??= {};
      for (final item in mnemonicsList) {
        final m = Mnemonic.fromJson(item as Map<String, dynamic>);
        _cache![m.wordId] = m;
      }
      _loadedBooks.add(bookId);
    } catch (e) {
      // 词库无助记数据或加载失败，静默忽略
    }
  }

  /// 获取指定单词的助记数据
  static Future<Mnemonic?> getMnemonic(String wordId, String bookId) async {
    await loadBook(bookId);
    return _cache?[wordId];
  }

  /// 获取指定单词的助记数据（同步，需先 loadBook）
  static Mnemonic? getMnemonicSync(String wordId) {
    return _cache?[wordId];
  }

  /// 清除缓存（用于测试）
  static void clearCache() {
    _cache = null;
    _loadedBooks.clear();
  }

  /// 获取助记数据资源路径
  static String _getAssetPath(String bookId) {
    switch (bookId) {
      case 'gaokao':
        return 'assets/data/mnemonics_gaokao.json';
      case 'it':
        return 'assets/data/mnemonics_it.json';
      default:
        return 'assets/data/mnemonics_$bookId.json';
    }
  }
}
