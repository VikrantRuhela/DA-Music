import 'dart:async';
import '../../shared/models/playback_state.dart';

/// Abstract AudioBackend to decouple the playback engine from any specific audio package.
abstract class AudioBackend {
  Stream<Duration> get positionStream;
  Stream<PlaybackStatus> get statusStream;
  Stream<double> get bufferProgressStream;

  Duration get currentPosition;
  PlaybackStatus get currentStatus;
  double get volume;

  Future<void> load(String source, Duration totalDuration);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume); // 0.0 to 1.0

  Future<void> dispose();
}
