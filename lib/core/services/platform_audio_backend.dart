import 'dart:async';

/// Sealed class hierarchy representing platform-level audio events.
sealed class PlatformAudioEvent {
  const PlatformAudioEvent();
}

class PlatformPlaybackStarted extends PlatformAudioEvent {
  const PlatformPlaybackStarted();
}

class PlatformPlaybackPaused extends PlatformAudioEvent {
  const PlatformPlaybackPaused();
}

class PlatformPlaybackStopped extends PlatformAudioEvent {
  const PlatformPlaybackStopped();
}

class PlatformPlaybackCompleted extends PlatformAudioEvent {
  const PlatformPlaybackCompleted();
}

class PlatformBufferingStarted extends PlatformAudioEvent {
  const PlatformBufferingStarted();
}

class PlatformBufferingFinished extends PlatformAudioEvent {
  const PlatformBufferingFinished();
}

class PlatformSeekCompleted extends PlatformAudioEvent {
  final Duration position;
  const PlatformSeekCompleted(this.position);
}

class PlatformVolumeChanged extends PlatformAudioEvent {
  final double volume;
  const PlatformVolumeChanged(this.volume);
}

class PlatformSpeedChanged extends PlatformAudioEvent {
  final double speed;
  const PlatformSpeedChanged(this.speed);
}

class PlatformEngineInitialized extends PlatformAudioEvent {
  const PlatformEngineInitialized();
}

class PlatformEngineDisposed extends PlatformAudioEvent {
  const PlatformEngineDisposed();
}

class PlatformPlaybackError extends PlatformAudioEvent {
  final String message;
  const PlatformPlaybackError(this.message);
}

/// Abstract contract isolating operating system level audio backend wrappers.
abstract class PlatformAudioBackend {
  Future<void> initialize();
  Future<void> dispose();
  Future<void> load(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> mute();
  Future<void> unmute();
  Future<void> setSpeed(double speed);
  Future<void> setLoopMode(bool enabled);
  Future<void> setShuffle(bool enabled);

  Duration get currentPosition;
  Duration get duration;
  Duration get bufferedPosition;
  double get speed;
  String get currentState;

  Stream<PlatformAudioEvent> get eventStream;
}
