import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logger_service.dart';

class SecureCredentialStore {
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(),
  );

  static const _keyCookies = 'ytm_secure_session_cookies';

  Future<void> saveCookies(String cookies) async {
    try {
      await _secureStorage.write(key: _keyCookies, value: cookies)
          .timeout(const Duration(seconds: 3));
    } catch (e, s) {
      DALogger.error('SecureCredentialStore: Failed or timed out writing cookies', e, s);
      rethrow;
    }
  }

  Future<String?> readCookies() async {
    try {
      return await _secureStorage.read(key: _keyCookies)
          .timeout(const Duration(seconds: 3));
    } catch (e, s) {
      DALogger.error('SecureCredentialStore: Failed or timed out reading cookies', e, s);
      return null;
    }
  }

  Future<void> clearCookies() async {
    try {
      await _secureStorage.delete(key: _keyCookies)
          .timeout(const Duration(seconds: 3));
    } catch (e, s) {
      DALogger.error('SecureCredentialStore: Failed or timed out deleting cookies', e, s);
      rethrow;
    }
  }
}
