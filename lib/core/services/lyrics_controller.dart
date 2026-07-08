import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/lyrics_repository.dart';
import '../../shared/models/music_models.dart' as shared;
import '../../shared/providers/player_providers.dart';
import '../../shared/providers/backend_providers.dart';
import 'lyrics_provider.dart';
import 'impl/lrclib_provider.dart';

class LyricsState {
  final String songId;
  final String plainLyrics;
  final Map<Duration, String>? syncedLyrics;
  final bool isLoading;
  final bool isInstrumental;
  final String? error;

  LyricsState({
    this.songId = '',
    this.plainLyrics = '',
    this.syncedLyrics,
    this.isLoading = false,
    this.isInstrumental = false,
    this.error,
  });

  LyricsState copyWith({
    String? songId,
    String? plainLyrics,
    Map<Duration, String>? syncedLyrics,
    bool? isLoading,
    bool? isInstrumental,
    String? error,
  }) {
    return LyricsState(
      songId: songId ?? this.songId,
      plainLyrics: plainLyrics ?? this.plainLyrics,
      syncedLyrics: syncedLyrics ?? this.syncedLyrics,
      isLoading: isLoading ?? this.isLoading,
      isInstrumental: isInstrumental ?? this.isInstrumental,
      error: error ?? this.error,
    );
  }
}

class LyricsController extends StateNotifier<LyricsState> {
  final LyricsRepository _lyricsRepository;
  final List<LyricsProvider> _providers;

  LyricsController(this._lyricsRepository, this._providers) : super(LyricsState());

  void clearLyrics() {
    state = LyricsState();
  }

  Future<void> loadLyricsForSong(shared.Song song) async {
    state = LyricsState(
      isLoading: true,
      songId: song.id,
      plainLyrics: '',
      syncedLyrics: null,
      isInstrumental: false,
      error: null,
    );
    
    // 1. Try local database cache lookup
    try {
      final cached = await _lyricsRepository.getLyricsBySongId(song.id);
      if (cached.plainLyrics == 'Instrumental') {
        state = state.copyWith(
          isLoading: false,
          isInstrumental: true,
          plainLyrics: 'Instrumental',
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        plainLyrics: cached.plainLyrics,
        syncedLyrics: cached.syncedLyrics,
      );
      return;
    } catch (_) {
      // Local cache miss, proceed to remote providers
    }

    // 2. Query remote lyrics providers
    for (final provider in _providers) {
      try {
        final lyrics = await provider.fetchLyrics(
          songId: song.id,
          title: song.title,
          artist: song.artist,
          album: song.album,
          duration: song.duration,
        );

        if (lyrics != null) {
          // Cache download results locally
          await _lyricsRepository.saveLyrics(lyrics);

          if (lyrics.plainLyrics == 'Instrumental') {
            state = state.copyWith(
              isLoading: false,
              isInstrumental: true,
              plainLyrics: 'Instrumental',
            );
            return;
          }

          state = state.copyWith(
            isLoading: false,
            plainLyrics: lyrics.plainLyrics,
            syncedLyrics: lyrics.syncedLyrics,
          );
          return;
        }
      } catch (_) {
        // Continue to next provider
      }
    }

    // 3. Set error state if no lyrics found
    state = state.copyWith(
      isLoading: false,
      plainLyrics: '',
      syncedLyrics: null,
      error: 'No lyrics available',
    );
  }
}

/// Registration provider
final lyricsControllerProvider = StateNotifierProvider<LyricsController, LyricsState>((ref) {
  final repo = ref.watch(lyricsRepositoryProvider);
  final providers = [LrcLibProvider()];
  final controller = LyricsController(repo, providers);
  
  ref.listen<shared.Song?>(currentSongProvider, (previous, next) {
    if (next != null) {
      controller.loadLyricsForSong(next);
    } else {
      controller.clearLyrics();
    }
  }, fireImmediately: true);

  return controller;
});
