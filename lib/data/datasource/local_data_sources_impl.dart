import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'data_sources.dart';
import '../models/data_models.dart';
import '../database/app_database.dart';
import '../../core/services/logger_service.dart';

class LocalMusicDataSourceImpl implements LocalMusicDataSource {
  final AppDatabase _db;

  LocalMusicDataSourceImpl(this._db);

  @override
  Future<List<SongModel>> getLikedSongs() async {
    final list = await (_db.select(_db.songs)..where((t) => t.liked.equals(true))).get();
    return list.map((s) => SongModel(
      id: s.id,
      title: s.title,
      artistId: s.artistId,
      albumId: s.albumId,
      durationMs: s.duration,
      artworkUrl: s.artwork,
      thumbnailUrl: s.thumbnail,
      isLiked: s.liked,
      isDownloaded: s.downloaded,
      sourceId: s.provider,
    )).toList();
  }

  @override
  Future<void> saveLikedSong(SongModel song) async {
    await _db.into(_db.songs).insertOnConflictUpdate(
      SongsCompanion(
        id: Value(song.id),
        title: Value(song.title),
        artistId: Value(song.artistId),
        albumId: Value(song.albumId),
        duration: Value(song.durationMs),
        artwork: Value(song.artworkUrl),
        thumbnail: Value(song.thumbnailUrl),
        liked: const Value(true),
        downloaded: Value(song.isDownloaded),
        provider: Value(song.sourceId),
      ),
    );
  }

  @override
  Future<void> removeLikedSong(String id) async {
    final song = await (_db.select(_db.songs)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (song != null) {
      await _db.into(_db.songs).insertOnConflictUpdate(
        SongsCompanion(
          id: Value(song.id),
          title: Value(song.title),
          artistId: Value(song.artistId),
          albumId: Value(song.albumId),
          duration: Value(song.duration),
          artwork: Value(song.artwork),
          thumbnail: Value(song.thumbnail),
          liked: const Value(false),
          downloaded: Value(song.downloaded),
          provider: Value(song.provider),
        ),
      );
    }
  }

  @override
  Future<List<PlaylistModel>> getPlaylists() async {
    final list = await _db.select(_db.playlists).get();
    return list.map((p) => PlaylistModel(
      id: p.id,
      title: p.title,
      description: p.description,
      coverUrl: p.cover,
      owner: p.owner,
      songIds: const [],
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    )).toList();
  }

  @override
  Future<void> savePlaylist(PlaylistModel playlist) async {
    await _db.into(_db.playlists).insertOnConflictUpdate(
      PlaylistsCompanion(
        id: Value(playlist.id),
        title: Value(playlist.title),
        cover: Value(playlist.coverUrl),
        owner: Value(playlist.owner),
        description: Value(playlist.description),
        createdAt: Value(playlist.createdAt),
        updatedAt: Value(playlist.updatedAt),
      ),
    );
  }

  @override
  Future<void> deletePlaylist(String id) async {
    await (_db.delete(_db.playlists)..where((t) => t.id.equals(id))).go();
  }
}

class CacheDataSourceImpl implements CacheDataSource {
  final AppDatabase _db;

  CacheDataSourceImpl(this._db);

  @override
  Future<String?> get(String key) async {
    final entry = await (_db.select(_db.settingsTable)..where((t) => t.key.equals(key))).getSingleOrNull();
    return entry?.value;
  }

  @override
  Future<void> put(String key, String value) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
      SettingsTableCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }

  @override
  Future<void> remove(String key) async {
    await (_db.delete(_db.settingsTable)..where((t) => t.key.equals(key))).go();
  }

  @override
  Future<void> clear() async {
    await _db.delete(_db.settingsTable).go();
  }
}

class ArtworkDataSourceImpl implements ArtworkDataSource {
  @override
  Future<String?> getArtworkUrl(String query) async {
    return 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819';
  }
}

class LyricsDataSourceImpl implements LyricsDataSource {
  final AppDatabase _db;

  LyricsDataSourceImpl(this._db);

  @override
  Future<LyricsModel> getLyrics(String songId) async {
    final entry = await (_db.select(_db.lyricsTable)..where((t) => t.songId.equals(songId))).getSingleOrNull();
    if (entry != null) {
      Map<Duration, String>? synced;
      if (entry.syncedLyrics != null) {
        try {
          final decoded = json.decode(entry.syncedLyrics!) as Map<String, dynamic>;
          synced = decoded.map((key, value) {
            final ms = int.parse(key);
            return MapEntry(Duration(milliseconds: ms), value as String);
          });
        } catch (_) {}
      }

      return LyricsModel(
        songId: entry.songId,
        plainLyrics: entry.plainLyrics,
        syncedLyrics: synced,
        language: 'en',
        provider: entry.provider,
      );
    }
    throw Exception('Lyrics not found locally.');
  }

  @override
  Future<void> saveLyrics(LyricsModel lyrics) async {
    String? syncedJson;
    final synced = lyrics.syncedLyrics;
    if (synced != null) {
      final map = synced.map((key, value) => MapEntry(key.inMilliseconds.toString(), value));
      syncedJson = json.encode(map);
    }

    await _db.lyricsDao.insertLyrics(
      LyricsTableCompanion(
        songId: Value(lyrics.songId),
        plainLyrics: Value(lyrics.plainLyrics),
        syncedLyrics: Value(syncedJson),
        provider: Value(lyrics.provider),
      ),
    );
  }
}

class HistoryDataSourceImpl implements HistoryDataSource {
  final AppDatabase _db;

  HistoryDataSourceImpl(this._db);

  @override
  Future<List<SongModel>> getRecentlyPlayed() async {
    final list = await _db.select(_db.songs).get();
    return list.map((s) => SongModel(
      id: s.id,
      title: s.title,
      artistId: s.artistId,
      albumId: s.albumId,
      durationMs: s.duration,
      artworkUrl: s.artwork,
      thumbnailUrl: s.thumbnail,
      isLiked: s.liked,
      isDownloaded: s.downloaded,
      sourceId: s.provider,
    )).toList();
  }

  @override
  Future<void> addSongToHistory(SongModel song) async {
    await _db.into(_db.songs).insertOnConflictUpdate(
      SongsCompanion(
        id: Value(song.id),
        title: Value(song.title),
        artistId: Value(song.artistId),
        albumId: Value(song.albumId),
        duration: Value(song.durationMs),
        artwork: Value(song.artworkUrl),
        thumbnail: Value(song.thumbnailUrl),
        liked: Value(song.isLiked),
        downloaded: Value(song.isDownloaded),
        provider: Value(song.sourceId),
      ),
    );
  }
}

class SettingsDataSourceImpl implements SettingsDataSource {
  SettingsDataSourceImpl(AppDatabase db);

  @override
  Future<SettingsModel> loadSettings() async {
    return SettingsModel(
      volume: 100,
      isMuted: false,
      repeatMode: 'off',
      isShuffle: false,
    );
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    DALogger.info('SettingsDataSourceImpl: Settings saved: $settings');
  }
}
