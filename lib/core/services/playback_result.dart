import '../errors/failures.dart';

/// Sealed class hierarchy representing explicit playback operation results.
sealed class PlaybackResult<T> {
  const PlaybackResult();
}

class PlaybackSuccess<T> extends PlaybackResult<T> {
  final T value;
  const PlaybackSuccess(this.value);
}

class PlaybackFailureResult<T> extends PlaybackResult<T> {
  final PlaybackFailure failure;
  const PlaybackFailureResult(this.failure);
}
