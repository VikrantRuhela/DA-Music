import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCredentialStore {
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(),
  );

  static const _keyCookies = 'ytm_secure_session_cookies';

  Future<void> saveCookies(String cookies) async {
    await _secureStorage.write(key: _keyCookies, value: cookies);
  }

  Future<String?> readCookies() async {
    return await _secureStorage.read(key: _keyCookies);
  }

  Future<void> clearCookies() async {
    await _secureStorage.delete(key: _keyCookies);
  }
}
