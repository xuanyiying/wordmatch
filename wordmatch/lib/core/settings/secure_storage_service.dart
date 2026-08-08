import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API Key 安全存储服务
///
/// 使用系统级加密存储（Android Keystore / iOS Keychain）保存 API Key，
/// 替代 SharedPreferences 明文存储，防止 Root/越狱设备或备份提取导致泄露。
///
/// 该服务只负责"敏感的密钥类"数据（API Key）。URL/模型名等非敏感配置
/// 仍使用 SharedPreferences，避免过度读写 Keychain。
class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _apiKeyKey = 'ai_api_key';

  /// 读取 API Key（未设置返回空串）
  static Future<String> readApiKey() async {
    try {
      return await _storage.read(key: _apiKeyKey) ?? '';
    } catch (_) {
      // 某些平台/版本 Keychain 读取异常时，返回空串降级，不阻塞启动
      return '';
    }
  }

  /// 写入 API Key
  static Future<void> writeApiKey(String apiKey) async {
    try {
      if (apiKey.isEmpty) {
        await _storage.delete(key: _apiKeyKey);
      } else {
        await _storage.write(key: _apiKeyKey, value: apiKey);
      }
    } catch (_) {
      // 写入失败时静默降级（至少保证应用可用）
    }
  }
}
