import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

/// SharedPreferences based implementation of StorageService.
class JsonStorageService implements StorageService {
  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<String?> getString(String key) async {
    _checkInit();
    return _prefs!.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    _checkInit();
    await _prefs!.setString(key, value);
  }

  @override
  Future<bool> containsKey(String key) async {
    _checkInit();
    return _prefs!.containsKey(key);
  }

  @override
  Future<void> remove(String key) async {
    _checkInit();
    await _prefs!.remove(key);
  }

  @override
  Future<void> clear() async {
    _checkInit();
    await _prefs!.clear();
  }

  void _checkInit() {
    if (_prefs == null) {
      throw StateError('StorageService is not initialized. Call init() first.');
    }
  }
}
