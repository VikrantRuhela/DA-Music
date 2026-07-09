import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/player_providers.dart';
import '../../../shared/models/music_models.dart';
import '../../../shared/models/playback_state.dart';
import 'providers/taste_engine_providers.dart';

class TastePlaybackObserver extends ConsumerStatefulWidget {
  final Widget child;

  const TastePlaybackObserver({super.key, required this.child});

  @override
  ConsumerState<TastePlaybackObserver> createState() => _TastePlaybackObserverState();
}

class _TastePlaybackObserverState extends ConsumerState<TastePlaybackObserver> {
  Song? _lastActiveSong;
  DateTime? _sessionStartTime;
  String? _sessionId;
  Duration _lastPosition = Duration.zero;

  @override
  Widget build(BuildContext context) {
    // 1. Listen to active song changes
    ref.listen<Song?>(currentSongProvider, (previous, next) {
      _handleSongChange(previous, next);
    });

    // 2. Listen to play status changes to capture final position on pause/stop
    ref.listen<PlaybackState>(playbackStateProvider, (previous, next) {
      if (_lastActiveSong != null) {
        final controller = ref.read(playbackControllerProvider);
        _lastPosition = controller.position;
      }
    });

    // Periodic check to capture live position
    ref.listen<int>(
      playbackControllerProvider.select((c) => c.position.inMilliseconds),
      (previous, next) {
        if (_lastActiveSong != null) {
          _lastPosition = Duration(milliseconds: next);
        }
      },
    );

    return widget.child;
  }

  void _handleSongChange(Song? previous, Song? next) {
    final now = DateTime.now();

    // 1. Terminate previous song session if it exists
    if (_lastActiveSong != null && _sessionStartTime != null && _sessionId != null) {
      final endTime = now;
      final finalSong = _lastActiveSong!;
      final finalSessionId = _sessionId!;
      final finalStartTime = _sessionStartTime!;
      final finalPosition = _lastPosition;

      // Submit session log to Taste Engine in the background
      Future.microtask(() {
        ref.read(tasteEngineNotifierProvider.notifier).recordPlaybackSession(
          songId: finalSong.id,
          title: finalSong.title,
          artist: finalSong.artist,
          album: finalSong.album,
          duration: finalSong.duration,
          position: finalPosition,
          startTime: finalStartTime,
          endTime: endTime,
          sessionId: finalSessionId,
        );
      });
    }

    // 2. Start a new session if a song is loaded
    if (next != null) {
      _lastActiveSong = next;
      _sessionStartTime = now;
      _sessionId = 'session_${now.millisecondsSinceEpoch}';
      _lastPosition = Duration.zero;
    } else {
      _lastActiveSong = null;
      _sessionStartTime = null;
      _sessionId = null;
      _lastPosition = Duration.zero;
    }
  }
}
