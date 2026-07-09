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
  final tasteState = ref.watch(tasteEngineNotifierProvider);
  if (!tasteState.isPersonalizationEnabled) return const [];

  final sourceManager = ref.watch(sourceManagerProvider);
  final downloadRepo = ref.watch(downloadRepositoryProvider);
  final downloadedSongs = await downloadRepo.getDownloadedSongs();

  List<Song> ytmRecs = [];
  final accountService = ref.watch(ytAccountServiceProvider);
  if (accountService.isLoggedIn) {
    try {
      ytmRecs = await accountService.fetchPersonalizedRecommendations();
    } catch (_) {}
  }

  return RecommendationEngine.generateRecommendations(
    dna: tasteState.dna,
    sourceManager: sourceManager,
    excludeDownloads: tasteState.excludeDownloads,
    downloadedSongs: downloadedSongs,
    ytmRecommendations: ytmRecs,
  );
});
