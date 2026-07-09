import 'dart:async';
import '../logger_service.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/lyrics.dart';
import '../../../domain/entities/search_result.dart';
import '../../../domain/entities/queue.dart';
import '../../../domain/entities/playback_state.dart';
import '../../../domain/entities/value_objects.dart';
import '../../../domain/entities/repeat_mode.dart';
import '../../../domain/repositories/song_repository.dart';
import '../../../domain/repositories/playlist_repository.dart';
import '../../../domain/repositories/lyrics_repository.dart';
import '../../../domain/repositories/search_repository.dart';
import '../../../domain/repositories/history_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/recommendation_repository.dart';
import '../playback_service.dart';
import '../search_service.dart';
import '../library_service.dart';
import '../recommendation_service.dart';
import '../history_service.dart';
import '../settings_service.dart';
import '../lyrics_service.dart';
import '../artwork_service.dart';
import '../download_service.dart';
import '../download_manager.dart';
import '../queue_service.dart';
import '../theme_service.dart';
import '../source_service.dart';
import '../../../../shared/models/music_models.dart' as shared;

// Helper to log all service actions (start, complete, duration, failure).
Future<T> _logAction<T>(String action, FutureOr<T> Function() call) async {
  final startTime = DateTime.now();
  DALogger.info('Starting action: $action');
  try {
    final result = await call();
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    DALogger.info('Completed action: $action in ${duration}ms');
    return result;
  } catch (e, stackTrace) {
    DALogger.error('Failed action: $action', e, stackTrace);
    rethrow;
  }
}

/// Concrete implementation of PlaybackService.
class PlaybackServiceImpl implements PlaybackService {
  final StreamController<PlaybackState> _stateController = StreamController<PlaybackState>.broadcast();

  PlaybackServiceImpl() {
    _stateController.add(const PlaybackIdle());
  }

  @override
  Stream<PlaybackState> get stateStream => _stateController.stream;

  @override
  Future<void> play(Song song) => _logAction('PlaybackService.play', () async {
    _stateController.add(PlaybackLoading(song: song));
    _stateController.add(PlaybackPlaying(song: song, position: Duration.zero, duration: song.duration.value));
  });

  @override
  Future<void> pause() => _logAction('PlaybackService.pause', () async {});

  @override
  Future<void> resume() => _logAction('PlaybackService.resume', () async {});

  @override
  Future<void> stop() => _logAction('PlaybackService.stop', () async {
    _stateController.add(const PlaybackIdle());
  });

  @override
  Future<void> seek(Duration position) => _logAction('PlaybackService.seek', () async {});
}

/// Concrete implementation of SearchService.
class SearchServiceImpl implements SearchService {
  final SearchRepository searchRepository;

  SearchServiceImpl({required this.searchRepository});

  @override
  Future<SearchResult> search(String query) => _logAction('SearchService.search', () async {
    return await searchRepository.search(query);
  });
}

/// Concrete implementation of LibraryService.
class LibraryServiceImpl implements LibraryService {
  final PlaylistRepository playlistRepository;
  final SongRepository songRepository;

  LibraryServiceImpl({
    required this.playlistRepository,
    required this.songRepository,
  });

  @override
  Future<List<Song>> getLikedSongs() => _logAction('LibraryService.getLikedSongs', () async {
    return [];
  });

  @override
  Future<void> likeSong(Song song) => _logAction('LibraryService.likeSong', () async {});

  @override
  Future<void> unlikeSong(String id) => _logAction('LibraryService.unlikeSong', () async {});

  @override
  Future<List<Playlist>> getPlaylists() => _logAction('LibraryService.getPlaylists', () async {
    return [];
  });
}

/// Concrete implementation of RecommendationService.
class RecommendationServiceImpl implements RecommendationService {
  final RecommendationRepository recommendationRepository;

  RecommendationServiceImpl({required this.recommendationRepository});

  @override
  Future<List<Song>> getRecommendations(String songId) =>
      _logAction('RecommendationService.getRecommendations', () async {
        return await recommendationRepository.getRecommendations(songId);
      });
}

/// Concrete implementation of HistoryService.
class HistoryServiceImpl implements HistoryService {
  final HistoryRepository historyRepository;

  HistoryServiceImpl({required this.historyRepository});

  @override
  Future<List<Song>> getRecentlyPlayed() => _logAction('HistoryService.getRecentlyPlayed', () async {
    return await historyRepository.getRecentlyPlayed();
  });

  @override
  Future<void> recordPlay(Song song) => _logAction('HistoryService.recordPlay', () async {
    await historyRepository.addSongToHistory(song);
  });
}

/// Concrete implementation of SettingsService.
class SettingsServiceImpl implements SettingsService {
  final SettingsRepository settingsRepository;

  SettingsServiceImpl({required this.settingsRepository});

  @override
  Future<shared.PlayerSettings> loadSettings() => _logAction('SettingsService.loadSettings', () async {
    return await settingsRepository.loadSettings();
  });

  @override
  Future<void> saveSettings(shared.PlayerSettings settings) =>
      _logAction('SettingsService.saveSettings', () async {
        await settingsRepository.saveSettings(settings);
      });
}

/// Concrete implementation of LyricsService.
class LyricsServiceImpl implements LyricsService {
  final LyricsRepository lyricsRepository;

  LyricsServiceImpl({required this.lyricsRepository});

  @override
  Future<Lyrics> getLyrics(String songId) => _logAction('LyricsService.getLyrics', () async {
    return await lyricsRepository.getLyricsBySongId(songId);
  });
}

/// Concrete implementation of ArtworkService.
class ArtworkServiceImpl implements ArtworkService {
  ArtworkServiceImpl();

  @override
  Future<String?> getArtworkUrl(String query) => _logAction('ArtworkService.getArtworkUrl', () async {
    return null;
  });
}

/// Concrete implementation of DownloadService.
class DownloadServiceImpl implements DownloadService {
  final DownloadManager _downloadManager;
  DownloadServiceImpl(this._downloadManager);

  @override
  Future<void> downloadSong(Song song) => _logAction('DownloadService.downloadSong', () async {
    final sharedSong = shared.Song(
      id: song.id,
      title: song.title,
      artist: song.artistId,
      album: song.albumId,
      duration: song.duration.value,
      artworkUrl: song.artwork.url,
      source: song.sourceId,
      lyrics: null,
    );
    await _downloadManager.startDownload(sharedSong);
  });

  @override
  Future<void> pauseDownload(String songId) => _logAction('DownloadService.pauseDownload', () async {
    _downloadManager.pauseDownload(songId);
  });

  @override
  Future<void> resumeDownload(String songId) => _logAction('DownloadService.resumeDownload', () async {
    _downloadManager.resumeDownload(songId);
  });

  @override
  Future<void> cancelDownload(String songId) => _logAction('DownloadService.cancelDownload', () async {
    await _downloadManager.cancelDownload(songId);
  });
}

/// Concrete implementation of QueueService.
class QueueServiceImpl implements QueueService {
  final StreamController<Queue> _queueController = StreamController<Queue>.broadcast();
  Queue _currentQueue = Queue(songs: [], currentIndex: -1, repeatMode: RepeatMode.none, shuffleEnabled: false);

  QueueServiceImpl() {
    _queueController.add(_currentQueue);
  }

  @override
  Stream<Queue> get queueStream => _queueController.stream;

  @override
  Future<void> insertNext(Song song) => _logAction('QueueService.insertNext', () async {
    _currentQueue = _currentQueue.insert(song);
    _queueController.add(_currentQueue);
  });

  @override
  Future<void> move(int oldIndex, int newIndex) => _logAction('QueueService.move', () async {
    _currentQueue = _currentQueue.move(oldIndex, newIndex);
    _queueController.add(_currentQueue);
  });

  @override
  Future<void> remove(int index) => _logAction('QueueService.remove', () async {
    _currentQueue = _currentQueue.remove(index);
    _queueController.add(_currentQueue);
  });

  @override
  Future<void> clear() => _logAction('QueueService.clear', () async {
    _currentQueue = _currentQueue.clear();
    _queueController.add(_currentQueue);
  });
}

/// Concrete implementation of ThemeService.
class ThemeServiceImpl implements ThemeService {
  ThemeServiceImpl();

  @override
  Future<void> setAccentColor(ThemeColor color) => _logAction('ThemeService.setAccentColor', () async {});

  @override
  Future<void> toggleDarkMode(bool enabled) => _logAction('ThemeService.toggleDarkMode', () async {});
}

/// Concrete implementation of SourceService.
class SourceServiceImpl implements SourceService {
  SourceServiceImpl();

  @override
  Future<void> selectSource(Source source) => _logAction('SourceService.selectSource', () async {});

  @override
  Future<List<Source>> getAvailableSources() => _logAction('SourceService.getAvailableSources', () async {
    return [];
  });
}
