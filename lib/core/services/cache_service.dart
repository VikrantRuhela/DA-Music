abstract class CacheService {
  Future<String?> get(String key);
  Future<void> put(String key, String value);
  Future<void> clear();
}
