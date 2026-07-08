import '../../domain/entities/song.dart';
import '../../domain/entities/playback_state.dart';

abstract class PlaybackService {
  Future<void> play(Song song);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Stream<PlaybackState> get stateStream;
}
