import 'logger_service.dart';

enum CachePolicy {
  cacheFirst,
  networkFirst,
  networkOnly,
  cacheOnly,
  staleWhileRevalidate,
}

/// Cache entry wrapper holding creation time, expiration and last access.
class CacheEntry<T> {
  final T value;
  final DateTime createdAt;
  final Duration ttl;
  DateTime lastAccess;

  CacheEntry(this.value, this.ttl)
      : createdAt = DateTime.now(),
        lastAccess = DateTime.now();

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;
}

/// Thread-safe in-memory cache engine using LRU eviction and TTL checks.
class CacheEngine {
  final Map<String, CacheEntry<dynamic>> _cache = {};
  final int maxEntries;

  CacheEngine({this.maxEntries = 150});

  /// Retrieve cached entry, returning null if expired or not found.
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) {
      DALogger.info('CacheEngine: Cache MISS for key: "$key"');
      return null;
    }
    if (entry.isExpired) {
      DALogger.info('CacheEngine: Cache EXPIRED for key: "$key"');
      _cache.remove(key);
      return null;
    }
    entry.lastAccess = DateTime.now();
    DALogger.info('CacheEngine: Cache HIT for key: "$key"');
    return entry.value as T;
  }

  /// Store entry, evicting the least recently used keys if limit exceeded.
  void put<T>(String key, T value, Duration ttl) {
    if (_cache.length >= maxEntries) {
      _evictLRU();
    }
    _cache[key] = CacheEntry(value, ttl);
    DALogger.info('CacheEngine: Cache stored: "$key" with TTL: ${ttl.inMinutes} mins');
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  void _evictLRU() {
    if (_cache.isEmpty) return;
    String? oldestKey;
    DateTime? oldestAccess;
    for (final entry in _cache.entries) {
      if (oldestAccess == null || entry.value.lastAccess.isBefore(oldestAccess)) {
        oldestAccess = entry.value.lastAccess;
        oldestKey = entry.key;
      }
    }
    if (oldestKey != null) {
      DALogger.info('CacheEngine: LRU Eviction: removing "$oldestKey"');
      _cache.remove(oldestKey);
    }
  }
}
