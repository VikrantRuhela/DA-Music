import '../../domain/entities/song.dart';
import '../../domain/entities/queue.dart';
import '../../domain/entities/repeat_mode.dart';
import '../errors/failures.dart';

/// Sealed class hierarchy representing event-driven playback notifications.
sealed class PlaybackEvent {
  const PlaybackEvent();
}

class PlaybackStarted extends PlaybackEvent {
  final Song song;
  const PlaybackStarted(this.song);
}

class PlaybackPaused extends PlaybackEvent {
  const PlaybackPaused();
}

class PlaybackStopped extends PlaybackEvent {
  const PlaybackStopped();
}

class PlaybackResumed extends PlaybackEvent {
  const PlaybackResumed();
}

class SongChanged extends PlaybackEvent {
  final Song? song;
  const SongChanged(this.song);
}

class PositionChanged extends PlaybackEvent {
  final Duration position;
  const PositionChanged(this.position);
}

class DurationChanged extends PlaybackEvent {
  final Duration duration;
  const DurationChanged(this.duration);
}

class VolumeChanged extends PlaybackEvent {
  final double volume;
  const VolumeChanged(this.volume);
}

class QueueChanged extends PlaybackEvent {
  final Queue queue;
  const QueueChanged(this.queue);
}

class RepeatChanged extends PlaybackEvent {
  final RepeatMode repeatMode;
  const RepeatChanged(this.repeatMode);
}

class ShuffleChanged extends PlaybackEvent {
  final bool shuffleEnabled;
  const ShuffleChanged(this.shuffleEnabled);
}

class PlaybackCompleted extends PlaybackEvent {
  const PlaybackCompleted();
}

class PlaybackFailed extends PlaybackEvent {
  final PlaybackFailure failure;
  const PlaybackFailed(this.failure);
}
