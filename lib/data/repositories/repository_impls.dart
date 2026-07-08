import '../../core/errors/failures.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/song_repository.dart';
import '../../domain/repositories/album_repository.dart';
import '../../domain/repositories/artist_repository.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/repositories/lyrics_repository.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../datasource/data_sources.dart';
import '../models/data_models.dart';
import '../../../shared/models/music_models.dart' as shared;

/// Concrete implementation of SongRepository interface.
class SongRepositoryImpl implements SongRepository {
  final RemoteMusicDataSource remoteDataSource;

  SongRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Song> getSongById(String id) async {
    try {
      final model = await remoteDataSource.getSongById(id);
      return model.toEntity();
    } catch (e, stack) {
      throw NetworkFailure(
        message: 'Failed to retrieve song details from remote source.',
        exception: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<List<Song>> getSongsByQuery(String query) async {
    try {
      final models = await remoteDataSource.getSongsByQuery(query);
      return models.map((m) => m.toEntity()).toList();
    } catch (e, stack) {
      throw NetworkFailure(
        message: 'Failed to query remote songs database.',
        exception: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<List<Song>> getRelatedSongs(String songId) async {
    try {
      final models = await remoteDataSource.getRecommendations(songId);
      return models.map((m) => m.toEntity()).toList();
    } catch (e, stack) {
      throw NetworkFailure(
        message: 'Failed to retrieve related songs list.',
        exception: e,
        stackTrace: stack,
      );
    }
  }
}

/// Concrete implementation of AlbumRepository interface.
class AlbumRepositoryImpl implements AlbumRepository {
  final RemoteMusicDataSource remoteDataSource;

  AlbumRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Album> getAlbumById(String id) async {
    try {
      final model = await remoteDataSource.getAlbumById(id);
      return model.toEntity();
    } catch (e, stack) {
      throw NetworkFailure(
        message: 'Failed to retrieve album details from remote source.',
        exception: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<List<Album>> getAlbumsByQuery(String query) async {
    try {
      final models = await remoteDataSource.getAlbumsByQuery(query);
      return models.map((m) => m.toEntity()).toList();
    } catch (e, stack) {
      throw NetworkFailure(
        message: 'Failed to query remote albums database.',
        exception: e,
        stackTrace: stack,
      );
    }
  }
}

/// Concrete implementation of ArtistRepository interface.
class ArtistRepositoryImpl implements ArtistRepository {
  final RemoteMusicDataSource remoteDataSource;

  ArtistRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Artist> getArtistById(String id) async {
    try {
      final model = await remoteDataSource.getArtistById(id);
      return model.toEntity();
    } catch (e, stack) {
      throw NetworkFailure(
        message: 'Failed to retrieve artist details from remote source.',
        exception: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<List<Artist>> getArtistsByQuery(String query) async {
    try {
      final models = await remoteDataSource.getArtistsByQuery(query);
      return models.map((m) => m.toEntity()).toList();
    } catch (e, stack) {
      throw NetworkFailure(
        message: 'Failed to query remote artists database.',
        exception: e,
        stackTrace: stack,
      );
    }
  }
}

/// Concrete implementation of PlaylistRepository interface.
class PlaylistRepositoryImpl implements PlaylistRepository {
  final LocalMusicDataSource localDataSource;

  PlaylistRepositoryImpl({required this.localDataSource});

  @override
  Future<Playlist> getPlaylistById(String id) async {
    try {
      final playlists = await localDataSource.getPlaylists();
      final model = playlists.firstWhere((p) => p.id == id);
      return model.toEntity();
    } catch (e, stack) {
      throw DatabaseFailure(
        message: 'Failed to query local playlist database.',
        exception: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<List<Playlist>> getPlaylistsByQuery(String query) async {
    try {
      final playlists = await localDataSource.getPlaylists();
      return playlists
          .where((p) => p.title.toLowerCase().contains(query.toLowerCase()))
          .map((m) => m.toEntity())
          .toList();
    } catch (e, stack) {
      throw DatabaseFailure(
        message: 'Failed to query local playlist query matches.',
        exception: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> createPlaylist(String name) async {
    try {
      final model = PlaylistModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: name,
        description: '',
        coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819',
        owner: 'user',
        songIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDataSource.savePlaylist(model);
    } catch (e, stack) {
      throw DatabaseFailure(
        message: 'Failed to save new custom playlist.',
        exception: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> deletePlaylist(String id) async {
    try {
      await localDataSource.deletePlaylist(id);
    } catch (e, stack) {
      throw DatabaseFailure(
        message: 'Failed to delete selected playlist from database.',
        exception: e,
        stackTrace: stack,
      );
    }
  }
}

/// Concrete implementation of LyricsRepository interface.
class LyricsRepositoryImpl implements LyricsRepository {
  final LyricsDataSource lyricsDataSource;

  LyricsRepositoryImpl({required this.lyricsDataSource});

  @override
  Future<Lyrics> getLyricsBySongId(String songId) async {
    try {
      final model = await lyricsDataSource.getLyrics(songId);
      return model.toEntity();
    } catch (e, stack) {
      throw NetworkFailure(
        message: 'Failed to fetch lyrics data for selected song.',
        exception: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> saveLyrics(Lyrics lyrics) async {
    try {
      final model = LyricsModel.fromEntity(lyrics);
      await lyricsDataSource.saveLyrics(model);
    } catch (e, stack) {
      throw CacheFailure(
        message: 'Failed to cache lyrics to database.',
        exception: e,
        stackTrace: stack,
      );
    }
  }
}

/// Concrete implementation of SearchRepository interface.
class SearchRepositoryImpl implements SearchRepository {
  final RemoteMusicDataSource remoteDataSource;

  SearchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<SearchResult> search(String query) async {
    try {
      final model = await remoteDataSource.search(query);
      return model.toEntity();
    } catch (e, stack) {
      throw NetworkFailure(
        message: 'Failed to perform remote search query dispatch.',
        exception: e,
        stackTrace: stack,
      );
    }
  }
}

/// Concrete implementation of HistoryRepository interface.
class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryDataSource historyDataSource;

  HistoryRepositoryImpl({required this.historyDataSource});

  @override
  Future<List<Song>> getRecentlyPlayed() async {
    try {
      final models = await historyDataSource.getRecentlyPlayed();
      return models.map((m) => m.toEntity()).toList();
    } catch (e, stack) {
      throw CacheFailure(
        message: 'Failed to load local track listening history.',
        exception: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> addSongToHistory(Song song) async {
    try {
      final model = SongModel.fromEntity(song);
      await historyDataSource.addSongToHistory(model);
    } catch (e, stack) {
      throw CacheFailure(
        message: 'Failed to record track play to history cache.',
        exception: e,
        stackTrace: stack,
      );
    }
  }
}

/// Concrete implementation of SettingsRepository interface.
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDataSource settingsDataSource;

  SettingsRepositoryImpl({required this.settingsDataSource});

  @override
  Future<shared.PlayerSettings> loadSettings() async {
    try {
      final model = await settingsDataSource.loadSettings();
      return model.toShared();
    } catch (e, stack) {
      throw CacheFailure(
        message: 'Failed to load system settings from persistence storage.',
        exception: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> saveSettings(shared.PlayerSettings settings) async {
    try {
      final model = SettingsModel.fromShared(settings);
      await settingsDataSource.saveSettings(model);
    } catch (e, stack) {
      throw CacheFailure(
        message: 'Failed to serialize player configurations to settings storage.',
        exception: e,
        stackTrace: stack,
      );
    }
  }
}

/// Concrete implementation of RecommendationRepository interface.
class RecommendationRepositoryImpl implements RecommendationRepository {
  final RemoteMusicDataSource remoteDataSource;

  RecommendationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Song>> getRecommendations(String songId) async {
    try {
      final models = await remoteDataSource.getRecommendations(songId);
      return models.map((m) => m.toEntity()).toList();
    } catch (e, stack) {
      throw NetworkFailure(
        message: 'Failed to load recommendation matches.',
        exception: e,
        stackTrace: stack,
      );
    }
  }
}
