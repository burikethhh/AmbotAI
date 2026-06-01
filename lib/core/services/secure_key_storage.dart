import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeyStorage {
  SecureKeyStorage._();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const _keyGemini = 'api_gemini';
  static const _keyOpenRouter = 'api_openrouter';
  static const _keyQwen = 'api_qwen';
  static const _keyHfToken = 'api_huggingface';
  static const _keyNvidia = 'api_nvidia';
  static const _keyNvidia2 = 'api_nvidia_2';

  static Future<String?> getGeminiKey() => _storage.read(key: _keyGemini);
  static Future<String?> getOpenRouterKey() => _storage.read(key: _keyOpenRouter);
  static Future<String?> getQwenKey() => _storage.read(key: _keyQwen);
  static Future<String?> getHfToken() => _storage.read(key: _keyHfToken);
  static Future<String?> getNvidiaKey() => _storage.read(key: _keyNvidia);
  static Future<String?> getNvidiaKey2() => _storage.read(key: _keyNvidia2);

  static Future<void> setGeminiKey(String? value) =>
      value != null && value.isNotEmpty
          ? _storage.write(key: _keyGemini, value: value)
          : _storage.delete(key: _keyGemini);

  static Future<void> setOpenRouterKey(String? value) =>
      value != null && value.isNotEmpty
          ? _storage.write(key: _keyOpenRouter, value: value)
          : _storage.delete(key: _keyOpenRouter);

  static Future<void> setQwenKey(String? value) =>
      value != null && value.isNotEmpty
          ? _storage.write(key: _keyQwen, value: value)
          : _storage.delete(key: _keyQwen);

  static Future<void> setHfToken(String? value) =>
      value != null && value.isNotEmpty
          ? _storage.write(key: _keyHfToken, value: value)
          : _storage.delete(key: _keyHfToken);

  static Future<void> setNvidiaKey(String? value) =>
      value != null && value.isNotEmpty
          ? _storage.write(key: _keyNvidia, value: value)
          : _storage.delete(key: _keyNvidia);

  static Future<void> setNvidiaKey2(String? value) =>
      value != null && value.isNotEmpty
          ? _storage.write(key: _keyNvidia2, value: value)
          : _storage.delete(key: _keyNvidia2);

  static Future<void> clearAll() async {
    await _storage.delete(key: _keyGemini);
    await _storage.delete(key: _keyOpenRouter);
    await _storage.delete(key: _keyQwen);
    await _storage.delete(key: _keyHfToken);
    await _storage.delete(key: _keyNvidia);
    await _storage.delete(key: _keyNvidia2);
  }
}
