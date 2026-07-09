import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart' as db_class;
import '../../shared/models/music_models.dart';
import '../../core/services/download_manager.dart';
import '../../shared/providers/backend_providers.dart';

class DownloadRepository {
  final db_class.AppDatabase _db;

  DownloadRepository(this._db);

  Future<Song?> getSongById(String songId) async {
    final s = await (_db.select(_db.songs)..where((t) => t.id.equals(songId))).getSingleOrNull();
    if (s == null) return null;
    return Song(
      id: s.id,
      title: s.title,
      artist: s.artistId,
      album: s.albumId,
      duration: Duration(milliseconds: s.duration),
      artworkUrl: s.artwork.isEmpty ? null : s.artwork,
      source: s.provider,
      lyrics: null,
      isFavorite: s.liked,
    );
  }

  Future<void> saveSongMetadata(Song song, {required bool downloaded}) async {
    final existing = await (_db.select(_db.songs)..where((t) => t.id.equals(song.id))).getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.songs)..where((t) => t.id.equals(song.id))).write(
        db_class.SongsCompanion(
          downloaded: Value(downloaded),
        ),
      );
    } else {
      await _db.into(_db.songs).insert(
        db_class.SongsCompanion(
          id: Value(song.id),
          title: Value(song.title),
          artistId: Value(song.artist),
          albumId: Value(song.album),
          duration: Value(song.duration.inMilliseconds),
          artwork: Value(song.artworkUrl ?? ''),
          thumbnail: Value(song.artworkUrl ?? ''),
          liked: const Value(false),
          downloaded: Value(downloaded),
          provider: Value(song.source),
        ),
      );
    }
  }

  Future<void> saveDownloadTask(String songId, DownloadStatus status, double progress, String? localPath) async {
    final statusStr = status.name;
    final progressPct = (progress * 100).toInt();

    await _db.into(_db.downloads).insertOnConflictUpdate(
      db_class.DownloadsCompanion(
        songId: Value(songId),
        status: Value(statusStr),
        progress: Value(progressPct),
        localPath: Value(localPath),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteDownloadTask(String songId) async {
    await (alignmentDelete(songId));
  }

  Future<void> alignmentDelete(String songId) async {
    await (_db.delete(_db.downloads)..where((t) => t.songId.equals(songId))).go();
    final existing = await (_db.select(_db.songs)..where((t) => t.id.equals(songId))).getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.songs)..where((t) => t.id.equals(songId))).write(
        const db_class.SongsCompanion(
          downloaded: Value(false),
        ),
      );
    }
  }

  Future<List<DownloadTask>> getAllTasks() async {
    final downloadsList = await _db.select(_db.downloads).get();
    final List<DownloadTask> tasks = [];

    for (final d in downloadsList) {
      final song = await (_db.select(_db.songs)..where((t) => t.id.equals(d.songId))).getSingleOrNull();
      tasks.add(DownloadTask(
        songId: d.songId,
        title: song?.title ?? 'Unknown Song',
        artist: song?.artistId ?? 'Unknown Artist',
        status: _parseStatus(d.status),
        progress: d.progress / 100.0,
        localFilePath: d.localPath,
      ));
    }
    return tasks;
  }

  Future<List<Song>> getDownloadedSongs() async {
    final list = await (_db.select(_db.songs)..where((t) => t.downloaded.equals(true))).get();
    return list.map((s) => Song(
      id: s.id,
      title: s.title,
      artist: s.artistId,
      album: s.albumId,
      duration: Duration(milliseconds: s.duration),
      artworkUrl: s.artwork.isEmpty ? null : s.artwork,
      source: s.provider,
      lyrics: null,
      isFavorite: s.liked,
    )).toList();
  }

  DownloadStatus _parseStatus(String s) {
    switch (s) {
      case 'downloading': return DownloadStatus.downloading;
      case 'paused': return DownloadStatus.paused;
      case 'completed': return DownloadStatus.completed;
      case 'failed': return DownloadStatus.failed;
      case 'cancelled': return DownloadStatus.cancelled;
      default: return DownloadStatus.queued;
    }
  }
}

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DownloadRepository(db);
});
