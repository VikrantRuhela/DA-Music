/// Abstract storage interface for caching metadata, playlists and user library states.
abstract class StorageService {
  Future<void> init();
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<bool> containsKey(String key);
  Future<void> remove(String key);
  Future<void> clear();
}
