import 'dart:async';
import 'cache_engine.dart';
import 'logger_service.dart';
import '../errors/failures.dart';

enum RequestPriority {
  high,
  normal,
  background,
}

class RequestOptions {
  final CachePolicy policy;
  final Duration ttl;
  final RequestPriority priority;
  final int retryCount;
  final Duration timeout;

  const RequestOptions({
    this.policy = CachePolicy.cacheFirst,
    this.ttl = const Duration(minutes: 30),
    this.priority = RequestPriority.normal,
    this.retryCount = 2,
    this.timeout = const Duration(seconds: 15),
  });
}

/// Request Manager coordinating rate queues, deduplication, cache policies and timeouts.
class RequestManager {
  final CacheEngine _cacheEngine;
  final Map<String, Future<dynamic>> _activeRequests = {};

  RequestManager({CacheEngine? cacheEngine})
      : _cacheEngine = cacheEngine ?? CacheEngine();

  /// Execute an operation routing through caching layers and pending request deduplicators.
  Future<T> execute<T>({
    required String key,
    required Future<T> Function() fetch,
    RequestOptions options = const RequestOptions(),
  }) async {
    final policy = options.policy;

    switch (policy) {
      case CachePolicy.networkOnly:
        return await _fetchWithDeduplication(key, fetch, options);

      case CachePolicy.cacheOnly:
        final cached = _cacheEngine.get<T>(key);
        if (cached != null) return cached;
        throw CacheFailure(message: 'Requested cacheOnly item not found in cache for key: "$key"');

      case CachePolicy.cacheFirst:
        final cached = _cacheEngine.get<T>(key);
        if (cached != null) return cached;
        final fresh = await _fetchWithDeduplication(key, fetch, options);
        _cacheEngine.put(key, fresh, options.ttl);
        return fresh;

      case CachePolicy.networkFirst:
        try {
          final fresh = await _fetchWithDeduplication(key, fetch, options);
          _cacheEngine.put(key, fresh, options.ttl);
          return fresh;
        } catch (e) {
          DALogger.warning('RequestManager: Network request failed for key: "$key". Falling back to cache...');
          final cached = _cacheEngine.get<T>(key);
          if (cached != null) return cached;
          rethrow;
        }

      case CachePolicy.staleWhileRevalidate:
        final cached = _cacheEngine.get<T>(key);
        if (cached != null) {
          // Trigger network fetch in background to revalidate cache
          _fetchWithDeduplication(key, fetch, options).then((fresh) {
            _cacheEngine.put(key, fresh, options.ttl);
          }).catchError((err) {
            DALogger.warning('RequestManager: Background revalidation failed for key: "$key": $err');
          });
          return cached;
        }
        final fresh = await _fetchWithDeduplication(key, fetch, options);
        _cacheEngine.put(key, fresh, options.ttl);
        return fresh;
    }
  }

  Future<T> _fetchWithDeduplication<T>(
    String key,
    Future<T> Function() fetch,
    RequestOptions options,
  ) async {
    if (_activeRequests.containsKey(key)) {
      DALogger.info('RequestManager: Deduplicating concurrent request for key: "$key"');
      return await _activeRequests[key] as T;
    }

    final future = _fetchWithRetry(key, fetch, options).whenComplete(() {
      _activeRequests.remove(key);
    });
    _activeRequests[key] = future;
    return await future;
  }

  Future<T> _fetchWithRetry<T>(
    String key,
    Future<T> Function() fetch,
    RequestOptions options,
  ) async {
    int attempt = 0;
    while (true) {
      final startTime = DateTime.now();
      try {
        DALogger.info('RequestManager: Fetching key: "$key" (Attempt ${attempt + 1}/${options.retryCount + 1})');
        final result = await fetch().timeout(options.timeout);
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        DALogger.info('RequestManager: Completed fetch for key: "$key" in ${duration}ms');
        return result;
      } catch (e, stack) {
        attempt++;
        if (attempt > options.retryCount) {
          DALogger.error('RequestManager: Fetch failed after $attempt attempts for key: "$key"', e, stack);
          throw NetworkFailure(
            message: 'Failed to retrieve data after retries.',
            exception: e,
            stackTrace: stack,
          );
        }
        final delayMs = 300 * attempt;
        DALogger.warning('RequestManager: Fetch failed. Retrying in ${delayMs}ms...');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }
}
