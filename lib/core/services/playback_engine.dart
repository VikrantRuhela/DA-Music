import '../../domain/entities/song.dart';
import '../../domain/entities/queue.dart';
import '../../domain/entities/playback_session.dart';
import '../../domain/entities/repeat_mode.dart';
import 'playback_result.dart';

/// Abstract Playback Engine contract definition for platform-agnostic audio wrappers.
abstract class PlaybackEngine {
  Future<PlaybackResult<void>> initialize();
  Future<PlaybackResult<void>> dispose();
  Future<PlaybackResult<void>> load(Song song);
  Future<PlaybackResult<void>> play();
  Future<PlaybackResult<void>> pause();
  Future<PlaybackResult<void>> resume();
  Future<PlaybackResult<void>> stop();
  Future<PlaybackResult<void>> seek(Duration position);
  Future<PlaybackResult<void>> setVolume(double volume);
  Future<PlaybackResult<void>> mute();
  Future<PlaybackResult<void>> unmute();
  Future<PlaybackResult<void>> next();
  Future<PlaybackResult<void>> previous();
  Future<PlaybackResult<void>> setRepeatMode(RepeatMode mode);
  Future<PlaybackResult<void>> setShuffle(bool enabled);
  Future<PlaybackResult<void>> playQueue(Queue queue);
  Future<PlaybackResult<void>> restoreSession(PlaybackSession session);

  Duration get currentPosition;
  Duration get duration;
  Duration get bufferedPosition;
  Stream<Queue> get onQueueChanged;
}
