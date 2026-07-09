import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../playback_engine.dart';
import '../playback_result.dart';
import '../platform_audio_backend.dart';
import '../logger_service.dart';
import '../stream_resolver.dart';
import '../../errors/failures.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/queue.dart';
import '../../../domain/entities/playback_session.dart';
import '../../../domain/entities/repeat_mode.dart';

/// Production-grade implementation of PlaybackEngine wrapping a PlatformAudioBackend dependency.
class PlaybackEngineImpl implements PlaybackEngine {
  final PlatformAudioBackend _backend;
  final StreamResolver _streamResolver;

  Queue? _queue;
  final StreamController<Queue> _queueController = StreamController<Queue>.broadcast();
  List<int> _shuffledIndices = [];
  int _shuffledIndex = -1;
  StreamSubscription? _backendEventSub;

  PlaybackEngineImpl(this._backend, this._streamResolver);

  Future<PlaybackResult<T>> _runSafe<T>(String action, Future<T> Function() call) async {
    try {
      final value = await call();
      return PlaybackSuccess(value);
    } catch (e, stack) {
      DALogger.error('PlaybackEngine: Platform action failed: $action', e, stack);
      return PlaybackFailureResult(
        PlaybackFailure(
          message: 'Low-level platform exception during $action.',
          exception: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<PlaybackResult<void>> initialize() =>
      _runSafe('initialize', () async {
        await _backend.initialize();
        await _backendEventSub?.cancel();
        _backendEventSub = _backend.eventStream.listen((event) {
          if (event is PlatformPlaybackCompleted) {
            next(isManual: false);
          }
        });
      });

  @override
  Future<PlaybackResult<void>> dispose() =>
      _runSafe('dispose', () async {
        await _backendEventSub?.cancel();
        _backendEventSub = null;
        await _queueController.close();
        await _backend.dispose();
      });

  @override
  Future<PlaybackResult<void>> load(Song song) =>
      _runSafe('load', () async {
        await _backend.stop();

        final docDir = await getApplicationDocumentsDirectory();
        final localFile = File(p.join(docDir.path, 'da_music_downloads', '${song.id}.mp3'));

        if (localFile.existsSync()) {
          DALogger.info('PlaybackEngine: Playing local offline file: ${localFile.path}');
          await _backend.load(localFile.path);
        } else {
          final stream = await _streamResolver.resolve(
            trackId: song.id,
            providerId: song.sourceId,
          );
          // ignore: avoid_print
          print('Resolved stream URL: ${stream.streamUrl}');
          await _backend.load(stream.streamUrl);
        }
      });

  @override
  Future<PlaybackResult<void>> play() =>
      _runSafe('play', () => _backend.play());

  @override
  Future<PlaybackResult<void>> pause() =>
      _runSafe('pause', () => _backend.pause());

  @override
  Future<PlaybackResult<void>> resume() =>
      _runSafe('resume', () => _backend.resume());

  @override
  Future<PlaybackResult<void>> stop() =>
      _runSafe('stop', () => _backend.stop());

  @override
  Future<PlaybackResult<void>> seek(Duration position) =>
      _runSafe('seek', () => _backend.seek(position));

  @override
  Future<PlaybackResult<void>> setVolume(double volume) =>
      _runSafe('setVolume', () => _backend.setVolume(volume));

  @override
  Future<PlaybackResult<void>> mute() =>
      _runSafe('mute', () => _backend.mute());

  @override
  Future<PlaybackResult<void>> unmute() =>
      _runSafe('unmute', () => _backend.unmute());

  @override
  Stream<Queue> get onQueueChanged => _queueController.stream;

  @override
  Future<PlaybackResult<void>> next({bool isManual = true}) =>
      _runSafe('next', () async {
        final queue = _queue;
        if (queue == null || queue.songs.isEmpty) return;

        int nextIndex = queue.currentIndex;

        if (!isManual && queue.repeatMode == RepeatMode.one) {
          await load(queue.songs[queue.currentIndex]);
          await play();
          return;
        }

        if (queue.shuffleEnabled) {
          _shuffledIndex++;
          if (_shuffledIndex >= _shuffledIndices.length) {
            if (queue.repeatMode == RepeatMode.all) {
              _shuffledIndices.shuffle();
              _shuffledIndex = 0;
              nextIndex = _shuffledIndices[_shuffledIndex];
            } else {
              await stop();
              _shuffledIndex = _shuffledIndices.length - 1;
              _queue = queue.copyWith(currentIndex: -1);
              _queueController.add(_queue!);
              return;
            }
          } else {
            nextIndex = _shuffledIndices[_shuffledIndex];
          }
        } else {
          nextIndex = queue.currentIndex + 1;
          if (nextIndex >= queue.songs.length) {
            if (queue.repeatMode == RepeatMode.all) {
              nextIndex = 0;
            } else {
              await stop();
              _queue = queue.copyWith(currentIndex: -1);
              _queueController.add(_queue!);
              return;
            }
          }
        }

        _queue = queue.copyWith(currentIndex: nextIndex);
        _queueController.add(_queue!);
        await load(_queue!.songs[nextIndex]);
        await play();
      });

  @override
  Future<PlaybackResult<void>> previous() =>
      _runSafe('previous', () async {
        final queue = _queue;
        if (queue == null || queue.songs.isEmpty) return;

        int prevIndex = queue.currentIndex;

        if (queue.shuffleEnabled) {
          _shuffledIndex--;
          if (_shuffledIndex < 0) {
            if (queue.repeatMode == RepeatMode.all) {
              _shuffledIndex = _shuffledIndices.length - 1;
              prevIndex = _shuffledIndices[_shuffledIndex];
            } else {
              _shuffledIndex = 0;
              return;
            }
          } else {
            prevIndex = _shuffledIndices[_shuffledIndex];
          }
        } else {
          prevIndex = queue.currentIndex - 1;
          if (prevIndex < 0) {
            if (queue.repeatMode == RepeatMode.all) {
              prevIndex = queue.songs.length - 1;
            } else {
              prevIndex = 0;
            }
          }
        }

        _queue = queue.copyWith(currentIndex: prevIndex);
        _queueController.add(_queue!);
        await load(_queue!.songs[prevIndex]);
        await play();
      });

  @override
  Future<PlaybackResult<void>> setRepeatMode(RepeatMode mode) =>
      _runSafe('setRepeatMode', () async {
        await _backend.setLoopMode(mode == RepeatMode.one);
        if (_queue != null) {
          _queue = _queue!.copyWith(repeatMode: mode);
          _queueController.add(_queue!);
        }
      });

  @override
  Future<PlaybackResult<void>> setShuffle(bool enabled) =>
      _runSafe('setShuffle', () async {
        await _backend.setShuffle(enabled);
        if (_queue != null) {
          _queue = _queue!.copyWith(shuffleEnabled: enabled);
          _updateShuffleIndices();
          _queueController.add(_queue!);
        }
      });

  @override
  Future<PlaybackResult<void>> playQueue(Queue queue) =>
      _runSafe('playQueue', () async {
        final prevQueue = _queue;
        _queue = queue;
        _updateShuffleIndices();
        _queueController.add(_queue!);

        final bool isSameSong = prevQueue != null &&
            prevQueue.songs.isNotEmpty &&
            queue.songs.isNotEmpty &&
            prevQueue.currentIndex >= 0 &&
            queue.currentIndex >= 0 &&
            prevQueue.currentIndex < prevQueue.songs.length &&
            queue.currentIndex < queue.songs.length &&
            prevQueue.songs[prevQueue.currentIndex].id == queue.songs[queue.currentIndex].id;

        if (isSameSong) {
          return;
        }

        if (_queue!.songs.isNotEmpty && _queue!.currentIndex >= 0 && _queue!.currentIndex < _queue!.songs.length) {
          await load(_queue!.songs[_queue!.currentIndex]);
          await play();
        }
      });

  void _updateShuffleIndices() {
    final queue = _queue;
    if (queue == null) return;
    if (queue.shuffleEnabled) {
      _shuffledIndices = List.generate(queue.songs.length, (i) => i);
      final currIndex = queue.currentIndex;
      if (currIndex >= 0 && currIndex < _shuffledIndices.length) {
        _shuffledIndices.remove(currIndex);
        _shuffledIndices.shuffle();
        _shuffledIndices.insert(0, currIndex);
        _shuffledIndex = 0;
      } else {
        _shuffledIndices.shuffle();
        _shuffledIndex = -1;
      }
    } else {
      _shuffledIndices = List.generate(queue.songs.length, (i) => i);
      _shuffledIndex = queue.currentIndex;
    }
  }

  @override
  Future<PlaybackResult<void>> restoreSession(PlaybackSession session) =>
      _runSafe('restoreSession', () async {
        await _backend.setVolume(session.volume);
        await _backend.setSpeed(session.playbackSpeed);
        if (session.currentSong != null) {
          await _backend.load(session.currentSong!.sourceId);
          await _backend.seek(session.position);
        }
      });

  @override
  Duration get currentPosition => _backend.currentPosition;

  @override
  Duration get duration => _backend.duration;

  @override
  Duration get bufferedPosition => _backend.bufferedPosition;
}
