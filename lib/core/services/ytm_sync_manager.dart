// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Music Contributors
// Licensed under GPL-3.0.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'youtube_music_account_service.dart';
import 'logger_service.dart';
import '../../shared/models/music_models.dart';

enum YtmSyncStatus { idle, syncing, success, failed }

class YtmSyncManager extends ChangeNotifier {
  final StorageService _storage;
  final YouTubeMusicAccountService _accountService;

  YtmSyncStatus _status = YtmSyncStatus.idle;
  DateTime? _lastSyncTime;
  DateTime? _lastSuccessfulSync;

  YtmSyncStatus get status => _status;
  bool get isSyncing => _status == YtmSyncStatus.syncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  DateTime? get lastSuccessfulSync => _lastSuccessfulSync;

  static const String _keyLastSync = 'ytm_sync_last_time';
  static const String _keyLastSuccess = 'ytm_sync_last_success';

  static const String keyLikedSongs = 'ytm_cache_liked_songs';
  static const String keyPlaylists = 'ytm_cache_playlists';
  static const String keyAlbums = 'ytm_cache_albums';
  static const String keyArtists = 'ytm_cache_artists';
  static const String keyHistory = 'ytm_cache_history';
  static const String keyRecommendations = 'ytm_cache_recommendations';

  YtmSyncManager(this._storage, this._accountService) {
    _loadSyncMetadata();
  }

  void _loadSyncMetadata() async {
    try {
      final lastSyncStr = await _storage.getString(_keyLastSync);
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.tryParse(lastSyncStr);
      }
      final lastSuccessStr = await _storage.getString(_keyLastSuccess);
      if (lastSuccessStr != null) {
        _lastSuccessfulSync = DateTime.tryParse(lastSuccessStr);
      }
      notifyListeners();
    } catch (e) {
      DALogger.error('YtmSyncManager: Failed to load sync metadata', e);
    }
  }

  Future<void> startSync({bool force = false}) async {
    if (_status == YtmSyncStatus.syncing) return;
    if (!_accountService.isLoggedIn) {
      DALogger.warning('YtmSyncManager: Cannot sync when user is not logged in.');
      return;
    }

    _status = YtmSyncStatus.syncing;
    _lastSyncTime = DateTime.now();
    await _storage.setString(_keyLastSync, _lastSyncTime!.toIso8601String());
    notifyListeners();

    int attempt = 0;
    const maxAttempts = 2;
    bool success = false;

    while (attempt < maxAttempts && !success) {
      try {
        DALogger.info('YtmSyncManager: Commencing background synchronization (Attempt ${attempt + 1})...');

        // 1. Fetch from remote
        final remoteLikedSongs = await _accountService.fetchLikedSongs();
        DALogger.info('YtmSyncManager: Fetched remote Liked Songs. Parsed Count: ${remoteLikedSongs.length}');

        final remotePlaylists = await _accountService.fetchLibraryPlaylists();
        DALogger.info('YtmSyncManager: Fetched remote Playlists. Parsed Count: ${remotePlaylists.length}');

        final remoteAlbums = await _accountService.fetchLibraryAlbums();
        DALogger.info('YtmSyncManager: Fetched remote Albums. Parsed Count: ${remoteAlbums.length}');

        final remoteArtists = await _accountService.fetchLibraryArtists();
        DALogger.info('YtmSyncManager: Fetched remote Artists. Parsed Count: ${remoteArtists.length}');

        final remoteHistory = await _accountService.fetchHistory();
        DALogger.info('YtmSyncManager: Fetched remote History. Parsed Count: ${remoteHistory.length}');

        final remoteRecs = await _accountService.fetchPersonalizedRecommendations();
        DALogger.info('YtmSyncManager: Fetched remote Personalized Recommendations. Parsed Count: ${remoteRecs.length}');

        // 2. Incremental comparison and cache updates
        await _updateCacheIfChanged(keyLikedSongs, remoteLikedSongs.map((s) => s.toJson()).toList());
        await _updateCacheIfChanged(keyPlaylists, remotePlaylists.map((p) => p.toJson()).toList());
        await _updateCacheIfChanged(keyAlbums, remoteAlbums.map((a) => a.toJson()).toList());
        await _updateCacheIfChanged(keyArtists, remoteArtists.map((a) => a.toJson()).toList());
        await _updateCacheIfChanged(keyHistory, remoteHistory.map((s) => s.toJson()).toList());
        await _updateCacheIfChanged(keyRecommendations, remoteRecs.map((s) => s.toJson()).toList());

        success = true;
      } catch (e) {
        attempt++;
        DALogger.error('YtmSyncManager: Synchronization attempt $attempt failed.', e);
        if (attempt < maxAttempts) {
          await Future.delayed(Duration(seconds: 2 * attempt));
        }
      }
    }

    if (success) {
      _status = YtmSyncStatus.success;
      _lastSuccessfulSync = DateTime.now();
      await _storage.setString(_keyLastSuccess, _lastSuccessfulSync!.toIso8601String());
      DALogger.info('YtmSyncManager: Synchronization succeeded.');
    } else {
      _status = YtmSyncStatus.failed;
      DALogger.error('YtmSyncManager: Synchronization failed after $maxAttempts attempts.');
    }

    DALogger.info('YtmSyncManager: Dispatching UI Refresh Event via notifyListeners().');
    notifyListeners();
    
    // Return status back to idle after a short delay
    Future.delayed(const Duration(seconds: 3), () {
      _status = YtmSyncStatus.idle;
      notifyListeners();
    });
  }

  Future<void> _updateCacheIfChanged(String key, List<dynamic> freshList) async {
    final cachedStr = await _storage.getString(key);
    final freshStr = jsonEncode(freshList);

    if (cachedStr != freshStr) {
      await _storage.setString(key, freshStr);
      DALogger.info('YtmSyncManager: Cache updated for key: $key');
    } else {
      DALogger.info('YtmSyncManager: No changes detected for key: $key. Skipping write.');
    }
  }

  // Local Offline Accessors
  Future<List<Song>> getCachedLikedSongs() async {
    final cached = await _storage.getString(keyLikedSongs);
    if (cached == null) return const [];
    try {
      final List<dynamic> list = jsonDecode(cached);
      return list.map((s) => Song.fromJson(s)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<Playlist>> getCachedPlaylists() async {
    final cached = await _storage.getString(keyPlaylists);
    if (cached == null) return const [];
    try {
      final List<dynamic> list = jsonDecode(cached);
      return list.map((p) => Playlist.fromJson(p)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<Album>> getCachedAlbums() async {
    final cached = await _storage.getString(keyAlbums);
    if (cached == null) return const [];
    try {
      final List<dynamic> list = jsonDecode(cached);
      return list.map((a) => Album.fromJson(a)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<Artist>> getCachedArtists() async {
    final cached = await _storage.getString(keyArtists);
    if (cached == null) return const [];
    try {
      final List<dynamic> list = jsonDecode(cached);
      return list.map((a) => Artist.fromJson(a)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<Song>> getCachedHistory() async {
    final cached = await _storage.getString(keyHistory);
    if (cached == null) return const [];
    try {
      final List<dynamic> list = jsonDecode(cached);
      return list.map((s) => Song.fromJson(s)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<Song>> getCachedRecommendations() async {
    final cached = await _storage.getString(keyRecommendations);
    if (cached == null) return const [];
    try {
      final List<dynamic> list = jsonDecode(cached);
      return list.map((s) => Song.fromJson(s)).toList();
    } catch (_) {
      return const [];
    }
  }
}
