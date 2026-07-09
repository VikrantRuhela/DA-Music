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
      downloadCount: downloadedSongs.length,
      favoriteCount: likes.length,
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

    final log = {
      'songId': songId,
      'videoId': videoId ?? songId,
      'artistId': artistId ?? artist,
      'albumId': albumId ?? album,
      'songTitle': title,
      'artist': artist,
      'album': album,
      'genre': genre ?? 'Pop',
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

  return RecommendationEngine.generateRecommendations(
    dna: tasteState.dna,
    sourceManager: sourceManager,
    excludeDownloads: tasteState.excludeDownloads,
    downloadedSongs: downloadedSongs,
  );
});
