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

class TasteEngineState {
  final MusicDNA dna;
  final bool isLearningPaused;
  final bool isPersonalizationEnabled;
  final bool excludeDownloads;
  final List<Map<String, dynamic>> logs;
  final bool isLoading;

  const TasteEngineState({
    this.dna = const MusicDNA(),
    this.isLearningPaused = false,
    this.isPersonalizationEnabled = true,
    this.excludeDownloads = false,
    this.logs = const [],
    this.isLoading = false,
  });

  TasteEngineState copyWith({
    MusicDNA? dna,
    bool? isLearningPaused,
    bool? isPersonalizationEnabled,
    bool? excludeDownloads,
    List<Map<String, dynamic>>? logs,
    bool? isLoading,
  }) {
    return TasteEngineState(
      dna: dna ?? this.dna,
      isLearningPaused: isLearningPaused ?? this.isLearningPaused,
      isPersonalizationEnabled: isPersonalizationEnabled ?? this.isPersonalizationEnabled,
      excludeDownloads: excludeDownloads ?? this.excludeDownloads,
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
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
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final isLearningPaused = prefs.getBool('taste_learning_paused') ?? false;
    final isPersonalizationEnabled = prefs.getBool('taste_personalization_enabled') ?? true;
    final excludeDownloads = prefs.getBool('taste_exclude_downloads') ?? false;

    final logs = await _historyRepo.loadLogs();
    
    // Count favorites and downloads
    final downloadedSongs = await _downloadRepo.getDownloadedSongs();
    final likes = _ref.read(libraryManagerProvider).likedSongs;

    final dna = TasteAnalyzer.analyze(
      logs,
      downloadedSongs: downloadedSongs,
      likedSongs: likes,
    );

    state = TasteEngineState(
      dna: dna,
      isLearningPaused: isLearningPaused,
      isPersonalizationEnabled: isPersonalizationEnabled,
      excludeDownloads: excludeDownloads,
      logs: logs,
      isLoading: false,
    );
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

  Future<void> clearHistory() async {
    await _historyRepo.clearHistory();
    await _init();
  }

  Future<void> resetMusicDNA() async {
    await clearHistory();
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
  if (!isPersonalizationEnabled) return const [];

  final tasteState = ref.read(tasteEngineNotifierProvider);
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

final personalizedAlbumsProvider = FutureProvider<List<domain.Album>>((ref) async {
  final isPersonalizationEnabled = ref.watch(tasteEngineNotifierProvider.select((s) => s.isPersonalizationEnabled));
  final sourceManager = ref.watch(sourceManagerProvider);

  List<domain.Album> ytmAlbums = [];
  try {
    final genericFeed = await sourceManager.getHome();
    final albumsSection = genericFeed.sections.firstWhere((s) => s.type == 'albums');
    ytmAlbums = albumsSection.items.cast<domain.Album>().toList();
  } catch (_) {}

  if (!isPersonalizationEnabled) return ytmAlbums;

  final tasteState = ref.read(tasteEngineNotifierProvider);
  return RecommendationEngine.generateAlbumRecommendations(
    dna: tasteState.dna,
    sourceManager: sourceManager,
    ytmAlbums: ytmAlbums,
  );
});

final personalizedPlaylistsProvider = FutureProvider<List<domain.Playlist>>((ref) async {
  final isPersonalizationEnabled = ref.watch(tasteEngineNotifierProvider.select((s) => s.isPersonalizationEnabled));
  final sourceManager = ref.watch(sourceManagerProvider);

  List<domain.Playlist> ytmPlaylists = [];
  try {
    final genericFeed = await sourceManager.getHome();
    final playlistsSection = genericFeed.sections.firstWhere((s) => s.type == 'playlists');
    ytmPlaylists = playlistsSection.items.cast<domain.Playlist>().toList();
  } catch (_) {}

  if (!isPersonalizationEnabled) return ytmPlaylists;

  final tasteState = ref.read(tasteEngineNotifierProvider);
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
}

final personalizedSectionsProvider = FutureProvider<List<RecommendationSection>>((ref) async {
  final isPersonalizationEnabled = ref.watch(tasteEngineNotifierProvider.select((s) => s.isPersonalizationEnabled));
  
  final sourceManager = ref.watch(sourceManagerProvider);
  
  domain.HomeFeed? genericFeed;
  try {
    genericFeed = await sourceManager.getHome();
  } catch (_) {}

  final genericSongs = genericFeed?.sections.firstWhere((s) => s.type == 'recommended', orElse: () => domain.HomeFeedSection(title: '', type: 'recommended', items: const [])).items.cast<domain.Song>().toList() ?? const <domain.Song>[];
  final genericAlbums = genericFeed?.sections.firstWhere((s) => s.type == 'albums', orElse: () => domain.HomeFeedSection(title: '', type: 'albums', items: const [])).items.cast<domain.Album>().toList() ?? const <domain.Album>[];
  final genericPlaylists = genericFeed?.sections.firstWhere((s) => s.type == 'playlists', orElse: () => domain.HomeFeedSection(title: '', type: 'playlists', items: const [])).items.cast<domain.Playlist>().toList() ?? const <domain.Playlist>[];

  if (!isPersonalizationEnabled) {
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

  final tasteState = ref.read(tasteEngineNotifierProvider);
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
    final recSongs = await ref.read(personalizedRecommendationsProvider.future);
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
  } catch (_) {}

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
      becauseItems.addAll(searchRes.songs.take(10));
    } catch (_) {}
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
      similarArtistItems.addAll(searchRes.songs.take(10));
    } catch (_) {}
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
  } catch (_) {}
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
    } catch (_) {}
    if (newReleaseItems.isNotEmpty) {
      sections.add(RecommendationSection(
        title: 'New Releases for You',
        subtitle: 'Latest albums from $artist',
        type: 'new_releases',
        items: newReleaseItems,
      ));
    }
  }

  final trendingItems = <domain.Song>[];
  final favoriteGenre = dna.favoriteGenres.isNotEmpty ? dna.favoriteGenres.first : 'Pop';
  try {
    final searchRes = await sourceManager.activeAdapter.search('trending $favoriteGenre');
    trendingItems.addAll(searchRes.songs.take(10));
  } catch (_) {}
  sections.add(RecommendationSection(
    title: 'Trending for You',
    subtitle: 'Popular $favoriteGenre hits trending now',
    type: 'trending',
    items: trendingItems.isNotEmpty ? trendingItems : genericSongs,
  ));

  return sections;
});
