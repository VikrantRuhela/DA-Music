import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import 'library_providers.dart';
import '../../domain/repositories/song_repository.dart';
import '../../domain/repositories/album_repository.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/repositories/artist_repository.dart';
import '../../domain/repositories/lyrics_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../../core/services/playback_service.dart';
import '../../core/services/search_service.dart';
import '../../core/services/lyrics_service.dart';
import '../../core/services/artwork_service.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/history_service.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/library_service.dart';
import '../../core/services/download_service.dart';
import '../../core/services/queue_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/source_service.dart';
import '../../core/services/impl/service_impls.dart';
import '../../core/services/playback_engine.dart';
import '../../core/services/impl/playback_engine_impl.dart';
import '../../core/services/impl/media_kit_audio_backend.dart';
import '../../core/services/event_bus.dart';
import '../../core/services/cache_engine.dart';
import '../../core/services/request_manager.dart';
import '../../core/services/source_manager.dart';
import '../../core/services/youtube_music_adapter.dart';
import '../../core/services/stream_resolver.dart';
import '../../data/datasource/data_sources.dart';
import '../../data/datasource/remote_music_data_source_impl.dart';
import '../../data/datasource/local_data_sources_impl.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/repository_impls.dart';

/// Centralized configuration provider.
final appConfigProvider = Provider<AppConfig>((ref) {
  return const AppConfig(
    environment: Environment.development,
    apiVersion: 'v1',
    buildSuffix: 'dev',
    versionString: '1.0.0',
  );
});

// --- Abstract Data Sources DI ---

final sourceManagerProvider = Provider<SourceManager>((ref) {
  final manager = SourceManager();
  manager.registerAdapter(YouTubeMusicAdapter());
  manager.selectSource('youtube_music');
  return manager;
});

final remoteMusicDataSourceProvider = Provider<RemoteMusicDataSource>((ref) {
  return RemoteMusicDataSourceImpl(
    sourceManager: ref.watch(sourceManagerProvider),
  );
});

final streamResolverProvider = Provider<StreamResolver>((ref) {
  return StreamResolver(
    ref.watch(sourceManagerProvider),
  );
});

final localMusicDataSourceProvider = Provider<LocalMusicDataSource>((ref) {
  return LocalMusicDataSourceImpl(ref.watch(appDatabaseProvider));
});

final cacheDataSourceProvider = Provider<CacheDataSource>((ref) {
  return CacheDataSourceImpl(ref.watch(appDatabaseProvider));
});

final artworkDataSourceProvider = Provider<ArtworkDataSource>((ref) {
  return ArtworkDataSourceImpl();
});

final lyricsDataSourceProvider = Provider<LyricsDataSource>((ref) {
  return LyricsDataSourceImpl(ref.watch(appDatabaseProvider));
});

final historyDataSourceProvider = Provider<HistoryDataSource>((ref) {
  return HistoryDataSourceImpl(ref.watch(appDatabaseProvider));
});

final settingsDataSourceProvider = Provider<SettingsDataSource>((ref) {
  return SettingsDataSourceImpl(ref.watch(appDatabaseProvider));
});

// --- Concrete Domain Repositories DI ---

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepositoryImpl(
    remoteDataSource: ref.watch(remoteMusicDataSourceProvider),
  );
});

final albumRepositoryProvider = Provider<AlbumRepository>((ref) {
  return AlbumRepositoryImpl(
    remoteDataSource: ref.watch(remoteMusicDataSourceProvider),
  );
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepositoryImpl(
    localDataSource: ref.watch(localMusicDataSourceProvider),
  );
});

final artistRepositoryProvider = Provider<ArtistRepository>((ref) {
  return ArtistRepositoryImpl(
    remoteDataSource: ref.watch(remoteMusicDataSourceProvider),
  );
});

final lyricsRepositoryProvider = Provider<LyricsRepository>((ref) {
  return LyricsRepositoryImpl(
    lyricsDataSource: ref.watch(lyricsDataSourceProvider),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    settingsDataSource: ref.watch(settingsDataSourceProvider),
  );
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(
    historyDataSource: ref.watch(historyDataSourceProvider),
  );
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(
    remoteDataSource: ref.watch(remoteMusicDataSourceProvider),
  );
});

final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  return RecommendationRepositoryImpl(
    remoteDataSource: ref.watch(remoteMusicDataSourceProvider),
  );
});

// --- Core Services DI ---

final playbackServiceProvider = Provider<PlaybackService>((ref) {
  return PlaybackServiceImpl();
});

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchServiceImpl(
    searchRepository: ref.watch(searchRepositoryProvider),
  );
});

final lyricsServiceProvider = Provider<LyricsService>((ref) {
  return LyricsServiceImpl(
    lyricsRepository: ref.watch(lyricsRepositoryProvider),
  );
});

final artworkServiceProvider = Provider<ArtworkService>((ref) {
  return ArtworkServiceImpl();
});

final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationServiceImpl(
    recommendationRepository: ref.watch(recommendationRepositoryProvider),
  );
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsServiceImpl(
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryServiceImpl(
    historyRepository: ref.watch(historyRepositoryProvider),
  );
});

final cacheServiceProvider = Provider<CacheService>((ref) {
  throw UnimplementedError('cacheServiceProvider is not implemented');
});

final libraryServiceProvider = Provider<LibraryService>((ref) {
  return LibraryServiceImpl(
    playlistRepository: ref.watch(playlistRepositoryProvider),
    songRepository: ref.watch(songRepositoryProvider),
  );
});

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final manager = ref.watch(downloadManagerProvider);
  return DownloadServiceImpl(manager);
});

final queueServiceProvider = Provider<QueueService>((ref) {
  return QueueServiceImpl();
});

final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeServiceImpl();
});

final sourceServiceProvider = Provider<SourceService>((ref) {
  return SourceServiceImpl();
});

final playbackEngineProvider = Provider<PlaybackEngine>((ref) {
  final backend = MediaKitAudioBackend();
  final resolver = ref.watch(streamResolverProvider);
  return PlaybackEngineImpl(backend, resolver);
});

final eventBusProvider = Provider<EventBus>((ref) {
  return EventBus();
});

final cacheEngineProvider = Provider<CacheEngine>((ref) {
  return CacheEngine();
});

final requestManagerProvider = Provider<RequestManager>((ref) {
  return RequestManager(
    cacheEngine: ref.watch(cacheEngineProvider),
  );
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
