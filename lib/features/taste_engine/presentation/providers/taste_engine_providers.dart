import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/listening_history_repository.dart';
import '../../domain/music_dna.dart';
import '../../domain/taste_analyzer.dart';
import '../../domain/recommendation_engine.dart';
import '../../../../data/repositories/download_repository.dart';
import '../../../../shared/providers/library_providers.dart';
import '../../../../shared/providers/backend_providers.dart';
import '../../../../shared/models/music_models.dart';
import '../../../../domain/entities/album.dart' as domain;
import '../../../../domain/entities/playlist.dart' as domain;
import '../../../../domain/entities/song.dart' as domain;
import '../../../../domain/entities/value_objects.dart' as domain;
import '../../../../domain/entities/home_feed.dart' as domain;
import '../../../../core/services/logger_service.dart';
import '../../../../shared/utils/home_feed_cache_serializer.dart';

class TasteEngineState {
  final MusicDNA dna;
  final bool isLearningPaused;
  final bool isPersonalizationEnabled;
  final bool excludeDownloads;
  final bool isSmartQueueEnabled;
  final List<Map<String, dynamic>> logs;
  final bool isLoading;
  final bool isInitialized;

  const TasteEngineState({
    this.dna = const MusicDNA(),
    this.isLearningPaused = false,
    this.isPersonalizationEnabled = true,
    this.excludeDownloads = false,
    this.isSmartQueueEnabled = true,
    this.logs = const [],
    this.isLoading = false,
    this.isInitialized = false,
  });

  TasteEngineState copyWith({
    MusicDNA? dna,
    bool? isLearningPaused,
    bool? isPersonalizationEnabled,
    bool? excludeDownloads,
    bool? isSmartQueueEnabled,
    List<Map<String, dynamic>>? logs,
    bool? isLoading,
    bool? isInitialized,
  }) {
    return TasteEngineState(
      dna: dna ?? this.dna,
      isLearningPaused: isLearningPaused ?? this.isLearningPaused,
      isPersonalizationEnabled: isPersonalizationEnabled ?? this.isPersonalizationEnabled,
      excludeDownloads: excludeDownloads ?? this.excludeDownloads,
      isSmartQueueEnabled: isSmartQueueEnabled ?? this.isSmartQueueEnabled,
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class TasteEngineNotifier extends StateNotifier<TasteEngineState> {
  final ListeningHistoryRepository _historyRepo;
  final DownloadRepository _downloadRepo;
  final Ref _ref;

  TasteEngineNotifier(this._historyRepo, this._downloadRepo, this._ref) : super(const TasteEngineState()) {
    _init();
  }

  static String detectGenre(String artist, String songTitle) {
    final artistLower = artist.toLowerCase();
    final titleLower = songTitle.toLowerCase();
    if (artistLower.contains('aujla') ||
        artistLower.contains('dosanjh') ||
        artistLower.contains('sidhu') ||
        artistLower.contains('maan') ||
        artistLower.contains('singh') ||
        artistLower.contains('amrit')) {
      return 'Punjabi';
    }
    if (artistLower.contains('eminem') ||
        artistLower.contains('drake') ||
        artistLower.contains('tupac') ||
        artistLower.contains('kanye') ||
        artistLower.contains('wayne') ||
        artistLower.contains('snoop')) {
      return 'Hip-Hop';
    }
    if (artistLower.contains('beatles') ||
        artistLower.contains('queen') ||
        artistLower.contains('pink floyd') ||
        artistLower.contains('led zeppelin')) {
      return 'Rock';
    }
    if (artistLower.contains('lo-fi') ||
        titleLower.contains('lofi') ||
        titleLower.contains('relax') ||
        titleLower.contains('study')) {
      return 'Lo-fi';
    }
    return 'Pop'; // default fallback
  }

  Future<void> _init() async {
    DALogger.info('TasteEngineNotifier: Initializing taste engine state...');
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLearningPaused = prefs.getBool('taste_learning_paused') ?? false;
      final isPersonalizationEnabled = prefs.getBool('taste_personalization_enabled') ?? true;
      final excludeDownloads = prefs.getBool('taste_exclude_downloads') ?? false;
      final isSmartQueueEnabled = prefs.getBool('taste_smart_queue_enabled') ?? true;

      DALogger.info('TasteEngineNotifier: Loading history logs...');
      final logs = await _historyRepo.loadLogs();
      
      // Count favorites and downloads
      DALogger.info('TasteEngineNotifier: Fetching downloaded songs and library likes...');
      final downloadedSongs = await _downloadRepo.getDownloadedSongs();
      final likes = _ref.read(libraryManagerProvider).likedSongs;

      DALogger.info('TasteEngineNotifier: Running TasteAnalyzer.analyze on logs=${logs.length}, downloads=${downloadedSongs.length}, likes=${likes.length}');
      final dna = TasteAnalyzer.analyze(
        logs,
        downloadedSongs: downloadedSongs,
        likedSongs: likes,
      );

      final sessionManager = _ref.read(sessionManagerProvider);
      final isGuestMode = sessionManager.isGuestMode;

      var finalDna = dna;
      if (isGuestMode) {
        final guestGenres = prefs.getStringList('ytm_guest_genres') ?? const [];
        final guestArtists = prefs.getStringList('ytm_guest_artists') ?? const [];
        final guestLanguages = prefs.getStringList('ytm_guest_languages') ?? const [];
        
        if (guestGenres.isNotEmpty || guestArtists.isNotEmpty || guestLanguages.isNotEmpty) {
          final mergedTopArtists = List<String>.from(dna.topArtists);
          for (final artist in guestArtists) {
            if (!mergedTopArtists.contains(artist)) {
              mergedTopArtists.add(artist);
            }
          }
          
          final mergedFavoriteGenres = List<String>.from(dna.favoriteGenres);
          for (final genre in guestGenres) {
            if (!mergedFavoriteGenres.contains(genre)) {
              mergedFavoriteGenres.add(genre);
            }
          }

          final Map<String, double> mergedArtistAffinities = Map<String, double>.from(dna.artistAffinities);
          for (final artist in guestArtists) {
            mergedArtistAffinities[artist] = (mergedArtistAffinities[artist] ?? 0.0) + 1.0;
          }

          final Map<String, double> mergedGenreAffinities = Map<String, double>.from(dna.genreAffinities);
          for (final genre in guestGenres) {
            mergedGenreAffinities[genre] = (mergedGenreAffinities[genre] ?? 0.0) + 1.0;
          }
          
          finalDna = MusicDNA(
            topArtists: mergedTopArtists,
            topAlbums: dna.topAlbums,
            topSongs: dna.topSongs,
            favoriteGenres: mergedFavoriteGenres,
            favoriteLanguages: guestLanguages.isNotEmpty ? guestLanguages : dna.favoriteLanguages,
            favoriteDecades: dna.favoriteDecades,
            listeningMood: dna.listeningMood,
            peakListeningTime: dna.peakListeningTime,
            averageSessionLengthMinutes: dna.averageSessionLengthMinutes,
            replayRate: dna.replayRate,
            skipRate: dna.skipRate,
            completionRate: dna.completionRate,
            downloadCount: dna.downloadCount,
            favoriteCount: dna.favoriteCount,
            artistAffinities: mergedArtistAffinities,
            genreAffinities: mergedGenreAffinities,
            songAffinities: dna.songAffinities,
            albumAffinities: dna.albumAffinities,
          );
        }
      }

      state = TasteEngineState(
        dna: finalDna,
        isLearningPaused: isLearningPaused,
        isPersonalizationEnabled: isPersonalizationEnabled,
        excludeDownloads: excludeDownloads,
        isSmartQueueEnabled: isSmartQueueEnabled,
        logs: logs,
        isLoading: false,
        isInitialized: true,
      );
      DALogger.info('TasteEngineNotifier: Taste engine state initialized successfully. Favorite genres: ${dna.favoriteGenres}');
    } catch (e, stack) {
      DALogger.error('TasteEngineNotifier: Initialization failed', e, stack);
      state = state.copyWith(isLoading: false, isInitialized: true);
    }
  }

  Future<void> recordPlaybackSession({
    required String songId,
    required String title,
    required String artist,
    required String album,
    required Duration duration,
    required Duration position,
    required DateTime startTime,
    required DateTime endTime,
    required String sessionId,
    String? videoId,
    String? artistId,
    String? albumId,
    String? genre,
    String? artworkUrl,
    String? source,
  }) async {
    if (state.isLearningPaused) return;

    final double completionPercentage = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds) * 100.0
        : 0.0;

    final detectedGenre = genre ?? detectGenre(artist, title);

    final log = {
      'songId': songId,
      'videoId': videoId ?? songId,
      'artistId': artistId ?? artist,
      'albumId': albumId ?? album,
      'songTitle': title,
      'artist': artist,
      'album': album,
      'genre': detectedGenre,
      'language': 'English',
      'durationMs': duration.inMilliseconds,
      'playbackPositionMs': position.inMilliseconds,
      'completionPercentage': completionPercentage,
      'completed': completionPercentage >= 85.0,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'sessionId': sessionId,
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'artworkUrl': artworkUrl ?? '',
      'source': source == 'youtube' ? 'youtube_music' : (source ?? 'youtube_music'),
    };

    await _historyRepo.appendLog(log);
    await _init(); // refresh DNA profile

    // Print Taste Engine log diagnostics
    final isFavorite = _ref.read(libraryManagerProvider).isSongLiked(songId);
    final downloadedList = await _downloadRepo.getDownloadedSongs();
    final isDownloaded = downloadedList.any((s) => s.id == songId);
    final isSkip = completionPercentage < 15.0;
    
    // Check replay status (more than 1 play of this song in history logs)
    final playsCount = state.logs.where((l) => l['songId'] == songId).length;
    final isReplay = playsCount > 1;

    final updatedArtistScore = state.dna.artistAffinities[artist] ?? 0.0;
    final updatedGenreScore = state.dna.genreAffinities[detectedGenre] ?? 0.0;
    final updatedSongScore = state.dna.songAffinities[title] ?? 0.0;

    final recommendations = await RecommendationEngine.generateRecommendations(
      dna: state.dna,
      sourceManager: _ref.read(sourceManagerProvider),
      excludeDownloads: state.excludeDownloads,
      downloadedSongs: downloadedList,
    );

    // ignore: avoid_print
    print('''
=== TASTE ENGINE PLAYBACK SESSION LOG ===
- Song ID: $songId
- Artist: $artist
- Genre: $detectedGenre
- Play Duration: ${position.inSeconds}s / ${duration.inSeconds}s
- Completion %: ${completionPercentage.toStringAsFixed(1)}%
- Skip: ${isSkip ? "Yes" : "No"}
- Replay: ${isReplay ? "Yes" : "No"}
- Favorite: ${isFavorite ? "Yes" : "No"}
- Download: ${isDownloaded ? "Yes" : "No"}

=== UPDATED AFFINITY SCORES ===
- Artist Affinity Score ($artist): ${updatedArtistScore.toStringAsFixed(2)}
- Genre Affinity Score ($detectedGenre): ${updatedGenreScore.toStringAsFixed(2)}
- Song Affinity Score ($title): ${updatedSongScore.toStringAsFixed(2)}

=== PERSONALIZED RECOMMENDATIONS ===''');

    for (int i = 0; i < recommendations.length; i++) {
      final rec = recommendations[i];
      String reason = 'Popular trending track';
      if (rec.artist == artist) {
        reason = 'Recommended based on your high affinity for artist "$artist"';
      } else if (state.dna.topArtists.contains(rec.artist)) {
        reason = 'Matches one of your top artists "${rec.artist}"';
      } else {
        reason = 'Matches your preference for the "$detectedGenre" genre';
      }
      // ignore: avoid_print
      print('${i + 1}. ${rec.title} by ${rec.artist} (Reason: $reason)');
    }
    // ignore: avoid_print
    print('========================================');
  }

  Future<void> recordSearch(String query) async {
    if (state.isLearningPaused || query.trim().isEmpty) return;
    
    // Save search log
    final log = {
      'songId': 'search_query',
      'songTitle': 'Search: $query',
      'artist': '',
      'album': '',
      'completionPercentage': 100.0,
      'completed': true,
      'startTime': DateTime.now().toIso8601String(),
      'endTime': DateTime.now().toIso8601String(),
      'sessionId': 'search',
    };

    await _historyRepo.appendLog(log);
    await _init();
  }

  Future<void> setLearningPaused(bool paused) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('taste_learning_paused', paused);
    state = state.copyWith(isLearningPaused: paused);
  }

  Future<void> setPersonalizationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('taste_personalization_enabled', enabled);
    state = state.copyWith(isPersonalizationEnabled: enabled);
  }

  Future<void> setExcludeDownloads(bool exclude) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('taste_exclude_downloads', exclude);
    state = state.copyWith(excludeDownloads: exclude);
  }

  Future<void> setSmartQueueEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('taste_smart_queue_enabled', enabled);
    state = state.copyWith(isSmartQueueEnabled: enabled);
  }

  Future<void> clearHistory() async {
    await _historyRepo.clearHistory();
    await _init();
  }

  Future<void> resetMusicDNA() async {
    await clearHistory();
  }

  Future<void> reload() async {
    await _init();
  }
}

final listeningHistoryRepositoryProvider = Provider<ListeningHistoryRepository>((ref) {
  return ListeningHistoryRepository();
});

final tasteEngineNotifierProvider = StateNotifierProvider<TasteEngineNotifier, TasteEngineState>((ref) {
  final historyRepo = ref.watch(listeningHistoryRepositoryProvider);
  final downloadRepo = ref.watch(downloadRepositoryProvider);
  return TasteEngineNotifier(historyRepo, downloadRepo, ref);
});

final personalizedRecommendationsProvider = FutureProvider<List<Song>>((ref) async {
  final isPersonalizationEnabled = ref.watch(tasteEngineNotifierProvider.select((s) => s.isPersonalizationEnabled));
  final excludeDownloads = ref.watch(tasteEngineNotifierProvider.select((s) => s.excludeDownloads));
  final isInitialized = ref.watch(tasteEngineNotifierProvider.select((s) => s.isInitialized));
  if (!isInitialized) return const [];
  if (!isPersonalizationEnabled) return const [];

  final tasteState = ref.watch(tasteEngineNotifierProvider);
  final sourceManager = ref.watch(sourceManagerProvider);
  final downloadRepo = ref.watch(downloadRepositoryProvider);
  final downloadedSongs = await downloadRepo.getDownloadedSongs();

  List<Song> ytmRecs = [];
  final accountService = ref.watch(ytAccountServiceProvider);
  if (accountService.isLoggedIn) {
    try {
      ytmRecs = await accountService.fetchPersonalizedRecommendations();
    } catch (_) {
      try {
        final syncManager = ref.read(ytmSyncManagerProvider);
        ytmRecs = await syncManager.getCachedRecommendations();
      } catch (_) {}
    }
  }

  return RecommendationEngine.generateRecommendations(
    dna: tasteState.dna,
    sourceManager: sourceManager,
    excludeDownloads: excludeDownloads,
    downloadedSongs: downloadedSongs,
    ytmRecommendations: ytmRecs,
  );
});

final genericHomeFeedProvider = FutureProvider<domain.HomeFeed>((ref) async {
  print('[HOME] Repository called');
  final sourceManager = ref.watch(sourceManagerProvider);
  
  DALogger.info('genericHomeFeedProvider: Fetching generic home feed...');
  try {
    final feed = await sourceManager.getHome();
    if (feed.sections.isNotEmpty && feed.sections.any((s) => s.items.isNotEmpty)) {
      DALogger.info('genericHomeFeedProvider: Successfully loaded from sourceManager.');
      return feed;
    }
    throw Exception('Home feed returned from sourceManager is empty');
  } catch (e, stack) {
    DALogger.error('genericHomeFeedProvider: Failed to load from sourceManager, trying offline cache fallback', e, stack);
    try {
      final storage = ref.read(storageServiceProvider);
      final cached = await storage.getString('ytm_cache_home_feed');
      if (cached != null && cached.isNotEmpty) {
        final feed = HomeFeedCacheSerializer.deserialize(cached);
        DALogger.info('genericHomeFeedProvider: Successfully loaded from offline cache fallback.');
        return feed;
      }
    } catch (cacheErr, cacheStack) {
      DALogger.error('genericHomeFeedProvider: Failed to load offline cache fallback', cacheErr, cacheStack);
    }

    // Build a fallback HomeFeed using public anonymous search endpoints
    DALogger.info('genericHomeFeedProvider: Offline cache is empty, generating search-based fallback feed...');
    try {
      final adapter = sourceManager.activeAdapter;
      
      // 1. Fetch songs
      final songsRes = await adapter.search('trending music hits');
      final fallbackSongs = songsRes.songs.map((s) => domain.Song(
        id: s.id,
        title: s.title,
        artistId: s.artistId,
        albumId: s.albumId,
        duration: s.duration,
        thumbnail: s.thumbnail,
        artwork: s.artwork,
        sourceId: s.sourceId,
      )).toList();

      // 2. Fetch albums
      final albumsRes = await adapter.search('top albums');
      final fallbackAlbums = albumsRes.albums.map((a) => domain.Album(
        id: a.id,
        title: a.title,
        artistId: a.artistId,
        cover: a.cover,
        year: a.year,
        trackCount: a.trackCount,
        duration: a.duration,
      )).toList();

      // 3. Fetch playlists
      final playlistsRes = await adapter.search('popular playlist mixes');
      final fallbackPlaylists = playlistsRes.playlists.map((p) => domain.Playlist(
        id: p.id,
        title: p.title,
        description: p.description,
        cover: p.cover,
        owner: p.owner,
        songIds: p.songIds,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
      )).toList();

      final fallbackFeed = domain.HomeFeed(
        sections: [
          domain.HomeFeedSection(
            title: 'Recommended for You',
            type: 'recommended',
            items: fallbackSongs,
          ),
          domain.HomeFeedSection(
            title: 'Trending Albums',
            type: 'albums',
            items: fallbackAlbums,
          ),
          domain.HomeFeedSection(
            title: 'Featured Playlists',
            type: 'playlists',
            items: fallbackPlaylists,
          ),
        ],
      );
      
      return fallbackFeed;
    } catch (fallbackErr, fallbackStack) {
      DALogger.error('genericHomeFeedProvider: Failed to generate search-based fallback feed', fallbackErr, fallbackStack);
    }

    return domain.HomeFeed(sections: []);
  }
});

final personalizedAlbumsProvider = FutureProvider<List<domain.Album>>((ref) async {
  final isPersonalizationEnabled = ref.watch(tasteEngineNotifierProvider.select((s) => s.isPersonalizationEnabled));
  final isInitialized = ref.watch(tasteEngineNotifierProvider.select((s) => s.isInitialized));
  if (!isInitialized) return const [];

  List<domain.Album> ytmAlbums = [];
  try {
    final genericFeed = await ref.watch(genericHomeFeedProvider.future);
    final albumsSection = genericFeed.sections.firstWhere((s) => s.type == 'albums');
    ytmAlbums = albumsSection.items.cast<domain.Album>().toList();
  } catch (_) {}

  if (!isPersonalizationEnabled) return ytmAlbums;

  final sourceManager = ref.watch(sourceManagerProvider);
  final tasteState = ref.watch(tasteEngineNotifierProvider);
  return RecommendationEngine.generateAlbumRecommendations(
    dna: tasteState.dna,
    sourceManager: sourceManager,
    ytmAlbums: ytmAlbums,
  );
});

final personalizedPlaylistsProvider = FutureProvider<List<domain.Playlist>>((ref) async {
  final isPersonalizationEnabled = ref.watch(tasteEngineNotifierProvider.select((s) => s.isPersonalizationEnabled));
  final isInitialized = ref.watch(tasteEngineNotifierProvider.select((s) => s.isInitialized));
  if (!isInitialized) return const [];

  List<domain.Playlist> ytmPlaylists = [];
  try {
    final genericFeed = await ref.watch(genericHomeFeedProvider.future);
    final playlistsSection = genericFeed.sections.firstWhere((s) => s.type == 'playlists');
    ytmPlaylists = playlistsSection.items.cast<domain.Playlist>().toList();
  } catch (_) {}

  if (!isPersonalizationEnabled) return ytmPlaylists;

  final sourceManager = ref.watch(sourceManagerProvider);
  final tasteState = ref.watch(tasteEngineNotifierProvider);
  return RecommendationEngine.generatePlaylistRecommendations(
    dna: tasteState.dna,
    sourceManager: sourceManager,
    ytmPlaylists: ytmPlaylists,
  );
});

class RecommendationSection {
  final String title;
  final String subtitle;
  final String type;
  final List<dynamic> items;

  const RecommendationSection({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.items,
  });
}final personalizedSectionsProvider = FutureProvider<List<RecommendationSection>>((ref) async {
  DALogger.info('[GUEST RECOMMENDATIONS] Initialization started.');
  final isPersonalizationEnabled = ref.watch(tasteEngineNotifierProvider.select((s) => s.isPersonalizationEnabled));
  final isInitialized = ref.watch(tasteEngineNotifierProvider.select((s) => s.isInitialized));
  if (!isInitialized) return const [];

  final storage = ref.watch(storageServiceProvider);
  try {
    DALogger.info('[GUEST RECOMMENDATIONS] Loading from cache...');
    final cached = await storage.getString('ytm_cache_personalized_sections');
    if (cached != null && cached.isNotEmpty) {
      final List<RecommendationSection> cachedSections = PersonalizedSectionsCacheSerializer.deserialize(cached);
      if (cachedSections.isNotEmpty) {
        DALogger.info('[GUEST RECOMMENDATIONS] Loaded personalized recommendations from cache. Section count: ${cachedSections.length}');
        return cachedSections;
      }
    }
  } catch (e, stack) {
    DALogger.error('[GUEST RECOMMENDATIONS] Cache lookup failed', e, stack);
  }

  DALogger.info('[GUEST RECOMMENDATIONS] Cache miss. Generating fresh recommendations...');
  final sourceManager = ref.watch(sourceManagerProvider);
  
  DALogger.info('personalizedSectionsProvider: Fetching home feed genericFeed via genericHomeFeedProvider...');
  domain.HomeFeed? genericFeed;
  try {
    genericFeed = await ref.watch(genericHomeFeedProvider.future);
  } catch (e, stack) {
    DALogger.error('[GUEST RECOMMENDATIONS] Failed to watch genericHomeFeedProvider', e, stack);
  }

  final rawGenericSongs = genericFeed?.sections.firstWhere((s) => s.type == 'recommended', orElse: () => domain.HomeFeedSection(title: '', type: 'recommended', items: const [])).items.cast<domain.Song>().toList() ?? const <domain.Song>[];
  // Filter non-music content from generic recommended songs
  final genericSongs = rawGenericSongs.where((song) {
    return RecommendationEngine.isValidMusicCandidate(
      song.title,
      song.artistId,
      song.duration.value,
    );
  }).toList();

  final genericAlbums = genericFeed?.sections.firstWhere((s) => s.type == 'albums', orElse: () => domain.HomeFeedSection(title: '', type: 'albums', items: const [])).items.cast<domain.Album>().toList() ?? const <domain.Album>[];
  final genericPlaylists = genericFeed?.sections.firstWhere((s) => s.type == 'playlists', orElse: () => domain.HomeFeedSection(title: '', type: 'playlists', items: const [])).items.cast<domain.Playlist>().toList() ?? const <domain.Playlist>[];

  if (!isPersonalizationEnabled) {
    print('[HOME] State updated');
    return [
      RecommendationSection(
        title: 'Trending For You',
        subtitle: 'Popular tracks picked for you',
        type: 'trending',
        items: genericSongs,
      ),
      RecommendationSection(
        title: 'Recommended Albums',
        subtitle: 'Albums you might like',
        type: 'similar_albums',
        items: genericAlbums,
      ),
      RecommendationSection(
        title: 'Featured Playlists',
        subtitle: 'Handpicked mixes and playlists',
        type: 'playlists',
        items: genericPlaylists,
      ),
    ];
  }

  final tasteState = ref.watch(tasteEngineNotifierProvider);
  final dna = tasteState.dna;
  final logs = tasteState.logs;

  final List<RecommendationSection> sections = [];

  final continueItems = <domain.Song>[];
  final seenIds = <String>{};
  for (final log in logs.reversed) {
    final id = log['songId'] as String? ?? '';
    if (id.isEmpty || id == 'search_query') continue;
    final double comp = (log['completionPercentage'] ?? 0.0).toDouble();
    if (comp >= 10.0 && comp < 85.0) {
      if (!seenIds.contains(id)) {
        seenIds.add(id);
        continueItems.add(domain.Song(
          id: id,
          title: log['songTitle'] ?? 'Unknown Track',
          artistId: log['artistId'] ?? log['artist'] ?? 'Unknown Artist',
          albumId: log['albumId'] ?? log['album'] ?? 'Unknown Album',
          duration: domain.DurationValue(Duration(milliseconds: log['durationMs'] ?? 0)),
          thumbnail: domain.Artwork(log['artworkUrl'] ?? ''),
          artwork: domain.Artwork(log['artworkUrl'] ?? ''),
          sourceId: log['source'] == 'youtube' ? 'youtube_music' : (log['source'] ?? 'youtube_music'),
        ));
      }
    }
    if (continueItems.length >= 8) break;
  }
  if (continueItems.isNotEmpty) {
    sections.add(RecommendationSection(
      title: 'Continue Listening',
      subtitle: 'Pick up where you left off',
      type: 'continue_listening',
      items: continueItems,
    ));
  }

  final recentItems = <domain.Song>[];
  final seenRecent = <String>{};
  for (final log in logs.reversed) {
    final id = log['songId'] as String? ?? '';
    if (id.isEmpty || id == 'search_query') continue;
    if (!seenRecent.contains(id)) {
      seenRecent.add(id);
      recentItems.add(domain.Song(
        id: id,
        title: log['songTitle'] ?? 'Unknown Track',
        artistId: log['artistId'] ?? log['artist'] ?? 'Unknown Artist',
        albumId: log['albumId'] ?? log['album'] ?? 'Unknown Album',
        duration: domain.DurationValue(Duration(milliseconds: log['durationMs'] ?? 0)),
        thumbnail: domain.Artwork(log['artworkUrl'] ?? ''),
        artwork: domain.Artwork(log['artworkUrl'] ?? ''),
        sourceId: log['source'] == 'youtube' ? 'youtube_music' : (log['source'] ?? 'youtube_music'),
      ));
    }
    if (recentItems.length >= 10) break;
  }
  if (recentItems.isNotEmpty) {
    sections.add(RecommendationSection(
      title: 'Recently Played',
      subtitle: 'Tracks you played recently',
      type: 'recently_played',
      items: recentItems,
    ));
  }

  final madeForYouItems = <domain.Song>[];
  try {
    final recSongs = await ref.watch(personalizedRecommendationsProvider.future);
    madeForYouItems.addAll(recSongs.map((s) => domain.Song(
      id: s.id,
      title: s.title,
      artistId: s.artist,
      albumId: s.album,
      duration: domain.DurationValue(s.duration),
      thumbnail: domain.Artwork(s.artworkUrl ?? ''),
      artwork: domain.Artwork(s.artworkUrl ?? ''),
      sourceId: s.source,
    )));
  } catch (e, stack) {
    DALogger.error('[GUEST RECOMMENDATIONS] Failed to load personalized recommendations', e, stack);
  }

  sections.add(RecommendationSection(
    title: 'Made For You',
    subtitle: 'A custom mix generated from your taste profile',
    type: 'made_for_you',
    items: madeForYouItems.isNotEmpty ? madeForYouItems : genericSongs,
  ));

  if (dna.topArtists.isNotEmpty) {
    final targetArtist = dna.topArtists.first;
    final becauseItems = <domain.Song>[];
    try {
      final searchRes = await sourceManager.activeAdapter.search('$targetArtist hits');
      final filtered = searchRes.songs.where((song) {
        final targetArtistLower = targetArtist.toLowerCase().trim();
        final songArtistLower = song.artistId.toLowerCase().trim();
        
        // Ensure the track is actually by or features the target artist
        if (!songArtistLower.contains(targetArtistLower) && !targetArtistLower.contains(songArtistLower)) {
          return false;
        }

        String? reason;
        final ok = RecommendationEngine.isValidMusicCandidate(
          song.title,
          song.artistId,
          song.duration.value,
          onReject: (r) => reason = r,
        );
        if (!ok) {
          print(' [Home Provider] REJECTED "Because You Listened" Candidate "${song.title}": $reason');
        }
        return ok;
      }).toList();
      becauseItems.addAll(filtered.take(10));
    } catch (e, stack) {
      DALogger.error('[GUEST RECOMMENDATIONS] Failed search for target artist $targetArtist hits', e, stack);
    }
    if (becauseItems.isNotEmpty) {
      sections.add(RecommendationSection(
        title: 'Because You Listened To $targetArtist',
        subtitle: 'More tracks from your top artist',
        type: 'because_you_listened',
        items: becauseItems,
      ));
    }
  }

  final rediscoverItems = <domain.Song>[];
  final lastPlayedIds = logs.reversed.take(15).map((l) => l['songId'] as String? ?? '').toSet();
  final sortedSongs = dna.songAffinities.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in sortedSongs) {
    final matchingLog = logs.firstWhere(
      (l) => l['songTitle'] == entry.key && !lastPlayedIds.contains(l['songId']),
      orElse: () => <String, dynamic>{},
    );
    if (matchingLog.isNotEmpty) {
      rediscoverItems.add(domain.Song(
        id: matchingLog['songId'] ?? '',
        title: matchingLog['songTitle'] ?? '',
        artistId: matchingLog['artistId'] ?? matchingLog['artist'] ?? '',
        albumId: matchingLog['albumId'] ?? matchingLog['album'] ?? '',
        duration: domain.DurationValue(Duration(milliseconds: matchingLog['durationMs'] ?? 0)),
        thumbnail: domain.Artwork(matchingLog['artworkUrl'] ?? ''),
        artwork: domain.Artwork(matchingLog['artworkUrl'] ?? ''),
        sourceId: matchingLog['source'] == 'youtube' ? 'youtube_music' : (matchingLog['source'] ?? 'youtube_music'),
      ));
    }
    if (rediscoverItems.length >= 8) break;
  }
  if (rediscoverItems.isNotEmpty) {
    sections.add(RecommendationSection(
      title: 'Rediscover Favorites',
      subtitle: 'Old favorites you haven\'t heard in a while',
      type: 'rediscover_favorites',
      items: rediscoverItems,
    ));
  }

  if (dna.topArtists.length > 1) {
    final secondArtist = dna.topArtists[1];
    final similarArtistItems = <domain.Song>[];
    try {
      final searchRes = await sourceManager.activeAdapter.search('$secondArtist hits');
      final filtered = searchRes.songs.where((song) {
        final targetArtistLower = secondArtist.toLowerCase().trim();
        final songArtistLower = song.artistId.toLowerCase().trim();
        
        // Ensure the track is actually by or features the second artist
        if (!songArtistLower.contains(targetArtistLower) && !targetArtistLower.contains(songArtistLower)) {
          return false;
        }

        String? reason;
        final ok = RecommendationEngine.isValidMusicCandidate(
          song.title,
          song.artistId,
          song.duration.value,
          onReject: (r) => reason = r,
        );
        if (!ok) {
          print(' [Home Provider] REJECTED "Similar Artist" Candidate "${song.title}": $reason');
        }
        return ok;
      }).toList();
      similarArtistItems.addAll(filtered.take(10));
    } catch (e, stack) {
      DALogger.error('[GUEST RECOMMENDATIONS] Failed search for second artist $secondArtist hits', e, stack);
    }
    if (similarArtistItems.isNotEmpty) {
      sections.add(RecommendationSection(
        title: 'Similar to $secondArtist',
        subtitle: 'Tracks inspired by your music preferences',
        type: 'similar_artists',
        items: similarArtistItems,
      ));
    }
  }

  final similarAlbumItems = <domain.Album>[];
  try {
    final recAlbums = await ref.read(personalizedAlbumsProvider.future);
    similarAlbumItems.addAll(recAlbums);
  } catch (e, stack) {
    DALogger.error('[GUEST RECOMMENDATIONS] Failed to load personalized albums', e, stack);
  }
  sections.add(RecommendationSection(
    title: 'Similar Albums',
    subtitle: 'Albums recommended for you',
    type: 'similar_albums',
    items: similarAlbumItems.isNotEmpty ? similarAlbumItems : genericAlbums,
  ));

  if (dna.topArtists.isNotEmpty) {
    final artist = dna.topArtists.first;
    final newReleaseItems = <domain.Album>[];
    try {
      final searchRes = await sourceManager.activeAdapter.search('new release $artist');
      newReleaseItems.addAll(searchRes.albums);
    } catch (e, stack) {
      DALogger.error('[GUEST RECOMMENDATIONS] Failed search for new releases of $artist', e, stack);
    }
    if (newReleaseItems.isNotEmpty) {
      sections.add(RecommendationSection(
        title: 'New Releases for You',
        subtitle: 'Latest albums from $artist',
        type: 'new_releases',
        items: newReleaseItems,
      ));
    }
  }

  final List<domain.Song> trendingItems = [];
  try {
    final List<Song> ytmGenericSongs = genericSongs.map<Song>((s) => Song(
      id: s.id,
      title: s.title,
      artist: s.artistId,
      album: s.albumId,
      duration: s.duration.value,
      artworkUrl: s.thumbnail.url,
      source: s.sourceId,
      lyrics: null,
    )).toList();

    final recTrending = await RecommendationEngine.generateTrendingRecommendations(
      dna: dna,
      sourceManager: sourceManager,
      genericSongs: ytmGenericSongs,
    );

    trendingItems.addAll(recTrending.map((s) => domain.Song(
      id: s.id,
      title: s.title,
      artistId: s.artist,
      albumId: s.album,
      duration: domain.DurationValue(s.duration),
      thumbnail: domain.Artwork(s.artworkUrl ?? ''),
      artwork: domain.Artwork(s.artworkUrl ?? ''),
      sourceId: s.source,
    )));
  } catch (e, stack) {
    DALogger.error('[GUEST RECOMMENDATIONS] Failed to generate trending recommendations', e, stack);
  }

  sections.add(RecommendationSection(
    title: 'Trending for You',
    subtitle: 'Popular hits trending now',
    type: 'trending',
    items: trendingItems.isNotEmpty ? trendingItems : genericSongs,
  ));

  try {
    final jsonStr = PersonalizedSectionsCacheSerializer.serialize(sections);
    await storage.setString('ytm_cache_personalized_sections', jsonStr);
    DALogger.info('[GUEST RECOMMENDATIONS] Cache created successfully. Recommendation section count: ${sections.length}');
  } catch (e, stack) {
    DALogger.error('[GUEST RECOMMENDATIONS] Failed to save cache', e, stack);
  }

  print('[HOME] State updated');
  return sections;
});

class PersonalizedSectionsCacheSerializer {
  static String serialize(List<RecommendationSection> sections) {
    final List<Map<String, dynamic>> sectionsList = [];
    for (final section in sections) {
      final List<Map<String, dynamic>> itemsList = [];
      for (final item in section.items) {
        if (item is domain.Song) {
          itemsList.add({
            '__type': 'song',
            'id': item.id,
            'title': item.title,
            'artistId': item.artistId,
            'albumId': item.albumId,
            'durationMs': item.duration.value.inMilliseconds,
            'thumbnailUrl': item.thumbnail.url,
            'artworkUrl': item.artwork.url,
            'sourceId': item.sourceId,
          });
        } else if (item is domain.Album) {
          itemsList.add({
            '__type': 'album',
            'id': item.id,
            'title': item.title,
            'artistId': item.artistId,
            'coverUrl': item.cover.url,
            'year': item.year,
            'trackCount': item.trackCount,
            'durationMs': item.duration.value.inMilliseconds,
          });
        } else if (item is domain.Playlist) {
          itemsList.add({
            '__type': 'playlist',
            'id': item.id,
            'title': item.title,
            'description': item.description,
            'coverUrl': item.cover.url,
            'owner': item.owner,
            'songIds': item.songIds,
            'createdAt': item.createdAt.toIso8601String(),
            'updatedAt': item.updatedAt.toIso8601String(),
          });
        }
      }
      sectionsList.add({
        'title': section.title,
        'subtitle': section.subtitle,
        'type': section.type,
        'items': itemsList,
      });
    }
    return jsonEncode(sectionsList);
  }

  static List<RecommendationSection> deserialize(String jsonStr) {
    try {
      final List<dynamic> sectionsList = jsonDecode(jsonStr);
      final List<RecommendationSection> sections = [];
      for (final secMap in sectionsList) {
        if (secMap is Map) {
          final String title = secMap['title'] as String? ?? 'Untitled Section';
          final String subtitle = secMap['subtitle'] as String? ?? '';
          final String type = secMap['type'] as String? ?? 'generic';
          final List<dynamic> itemsList = secMap['items'] as List? ?? [];
          final List<dynamic> items = [];

          for (final itemMap in itemsList) {
            if (itemMap is Map) {
              final typeKey = itemMap['__type'] as String?;
              if (typeKey == 'song') {
                items.add(domain.Song(
                  id: itemMap['id'] as String? ?? '',
                  title: itemMap['title'] as String? ?? '',
                  artistId: itemMap['artistId'] as String? ?? '',
                  albumId: itemMap['albumId'] as String? ?? '',
                  duration: domain.DurationValue(Duration(milliseconds: itemMap['durationMs'] as int? ?? 0)),
                  thumbnail: domain.Artwork(itemMap['thumbnailUrl'] as String?),
                  artwork: domain.Artwork(itemMap['artworkUrl'] as String?),
                  sourceId: itemMap['sourceId'] as String? ?? '',
                ));
              } else if (typeKey == 'album') {
                items.add(domain.Album(
                  id: itemMap['id'] as String? ?? '',
                  title: itemMap['title'] as String? ?? '',
                  artistId: itemMap['artistId'] as String? ?? '',
                  cover: domain.Artwork(itemMap['coverUrl'] as String?),
                  year: itemMap['year'] as int? ?? 2026,
                  trackCount: itemMap['trackCount'] as int? ?? 0,
                  duration: domain.DurationValue(Duration(milliseconds: itemMap['durationMs'] as int? ?? 0)),
                ));
              } else if (typeKey == 'playlist') {
                items.add(domain.Playlist(
                  id: itemMap['id'] as String? ?? '',
                  title: itemMap['title'] as String? ?? '',
                  description: itemMap['description'] as String? ?? '',
                  cover: domain.Artwork(itemMap['coverUrl'] as String?),
                  owner: itemMap['owner'] as String? ?? '',
                  songIds: List<String>.from(itemMap['songIds'] ?? []),
                  createdAt: DateTime.tryParse(itemMap['createdAt'] as String? ?? '') ?? DateTime.now(),
                  updatedAt: DateTime.tryParse(itemMap['updatedAt'] as String? ?? '') ?? DateTime.now(),
                ));
              }
            }
          }
          sections.add(RecommendationSection(
            title: title,
            subtitle: subtitle,
            type: type,
            items: items,
          ));
        }
      }
      return sections;
    } catch (_) {
      return [];
    }
  }
}
