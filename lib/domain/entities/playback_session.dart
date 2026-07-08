import 'song.dart';
import 'queue.dart';
import 'playback_state.dart';
import 'repeat_mode.dart';

/// Immutable domain entity representing a persistent audio playback session.
class PlaybackSession {
  final String sessionId;
  final Song? currentSong;
  final Queue queue;
  final Duration position;
  final Duration duration;
  final double volume; // 0.0 to 1.0
  final PlaybackState playbackState;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;
  final double playbackSpeed; // e.g. 1.0, 1.5
  final DateTime startedAt;
  final DateTime updatedAt;

  PlaybackSession({
    required this.sessionId,
    this.currentSong,
    required this.queue,
    required this.position,
    required this.duration,
    required this.volume,
    required this.playbackState,
    required this.repeatMode,
    required this.shuffleEnabled,
    required this.playbackSpeed,
    required this.startedAt,
    required this.updatedAt,
  })  : assert(sessionId.isNotEmpty, 'Session ID reference cannot be empty.'),
        assert(volume >= 0.0 && volume <= 1.0, 'Volume must be bounded between 0.0 and 1.0.'),
        assert(playbackSpeed > 0.0, 'Playback speed must be greater than zero.'),
        assert(!position.isNegative, 'Position cannot be negative.'),
        assert(!duration.isNegative, 'Duration cannot be negative.');

  PlaybackSession copyWith({
    String? sessionId,
    Song? currentSong,
    Queue? queue,
    Duration? position,
    Duration? duration,
    double? volume,
    PlaybackState? playbackState,
    RepeatMode? repeatMode,
    bool? shuffleEnabled,
    double? playbackSpeed,
    DateTime? startedAt,
    DateTime? updatedAt,
  }) {
    return PlaybackSession(
      sessionId: sessionId ?? this.sessionId,
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      playbackState: playbackState ?? this.playbackState,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackSession &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          currentSong == other.currentSong &&
          queue == other.queue &&
          position == other.position &&
          duration == other.duration &&
          volume == other.volume &&
          playbackState == other.playbackState &&
          repeatMode == other.repeatMode &&
          shuffleEnabled == other.shuffleEnabled &&
          playbackSpeed == other.playbackSpeed &&
          startedAt == other.startedAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      sessionId.hashCode ^
      currentSong.hashCode ^
      queue.hashCode ^
      position.hashCode ^
      duration.hashCode ^
      volume.hashCode ^
      playbackState.hashCode ^
      repeatMode.hashCode ^
      shuffleEnabled.hashCode ^
      playbackSpeed.hashCode ^
      startedAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'PlaybackSession{sessionId: $sessionId, currentSong: ${currentSong?.title}, volume: $volume, speed: $playbackSpeed}';
  }
}
