import 'song.dart';

/// Sealed class hierarchy representing rich states of the audio playback engine.
sealed class PlaybackState {
  final Duration position;
  final Duration duration;

  const PlaybackState({
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });
}

class PlaybackIdle extends PlaybackState {
  const PlaybackIdle() : super();

  @override
  String toString() => 'PlaybackIdle{}';
}

class PlaybackLoading extends PlaybackState {
  final Song song;
  const PlaybackLoading({required this.song}) : super();

  @override
  String toString() => 'PlaybackLoading{song: ${song.title}}';
}

class PlaybackPlaying extends PlaybackState {
  final Song song;

  const PlaybackPlaying({
    required this.song,
    required super.position,
    required super.duration,
  });

  @override
  String toString() =>
      'PlaybackPlaying{song: ${song.title}, position: $position, duration: $duration}';
}

class PlaybackPaused extends PlaybackState {
  final Song song;

  const PlaybackPaused({
    required this.song,
    required super.position,
    required super.duration,
  });

  @override
  String toString() =>
      'PlaybackPaused{song: ${song.title}, position: $position, duration: $duration}';
}

class PlaybackBuffering extends PlaybackState {
  final Song song;
  final double bufferingProgress; // 0.0 to 1.0

  const PlaybackBuffering({
    required this.song,
    required this.bufferingProgress,
    required super.position,
    required super.duration,
  });

  @override
  String toString() =>
      'PlaybackBuffering{song: ${song.title}, buffering: $bufferingProgress, position: $position, duration: $duration}';
}

class PlaybackCompleted extends PlaybackState {
  final Song song;
  const PlaybackCompleted({required this.song}) : super();

  @override
  String toString() => 'PlaybackCompleted{song: ${song.title}}';
}

class PlaybackError extends PlaybackState {
  final String errorMessage;
  const PlaybackError({required this.errorMessage}) : super();

  @override
  String toString() => 'PlaybackError{message: $errorMessage}';
}
