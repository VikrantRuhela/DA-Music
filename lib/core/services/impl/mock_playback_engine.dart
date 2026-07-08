import '../playback_engine.dart';
import '../playback_result.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/queue.dart';
import '../../../domain/entities/playback_session.dart';
import '../../../domain/entities/repeat_mode.dart';

/// Platform independent mock audio backend implementing the PlaybackEngine contract.
class MockPlaybackEngine implements PlaybackEngine {
  @override
  Future<PlaybackResult<void>> initialize() async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> dispose() async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> load(Song song) async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> play() async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> pause() async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> resume() async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> stop() async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> seek(Duration position) async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> setVolume(double volume) async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> mute() async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> unmute() async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> next() async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> previous() async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> setRepeatMode(RepeatMode mode) async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> setShuffle(bool enabled) async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> playQueue(Queue queue) async => const PlaybackSuccess(null);

  @override
  Future<PlaybackResult<void>> restoreSession(PlaybackSession session) async => const PlaybackSuccess(null);

  @override
  Duration get currentPosition => Duration.zero;

  @override
  Duration get duration => Duration.zero;

  @override
  Duration get bufferedPosition => Duration.zero;

  @override
  Stream<Queue> get onQueueChanged => const Stream.empty();
}
