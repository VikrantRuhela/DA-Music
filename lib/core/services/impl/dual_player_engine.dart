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

class DualPlayerEngine implements PlaybackEngine {
  final PlatformAudioBackend _backendA;
  final PlatformAudioBackend _backendB;
  final StreamResolver _streamResolver;

  bool Function()? isCrossfadeEnabled;
  int Function()? getCrossfadeDuration;

  late PlatformAudioBackend _activeBackend;
  late PlatformAudioBackend _standbyBackend;

  Queue? _queue;
  final StreamController<Queue> _queueController = StreamController<Queue>.broadcast();
  List<int> _shuffledIndices = [];
  int _shuffledIndex = -1;

  StreamSubscription? _subA;
  StreamSubscription? _subB;
  String? _currentlyLoadingSongId;

  double _masterVolume = 1.0;
  bool _isMuted = false;

  Timer? _crossfadeTimer;
  Timer? _standbyInitTimer;
  bool _isCrossfading = false;

  DualPlayerEngine(
    this._backendA,
    this._backendB,
    this._streamResolver, {
    this.isCrossfadeEnabled,
    this.getCrossfadeDuration,
  }) {
    _activeBackend = _backendA;
    _standbyBackend = _backendB;
  }

  Future<PlaybackResult<T>> _runSafe<T>(String action, Future<T> Function() call) async {
    try {
      final value = await call();
      return PlaybackSuccess(value);
    } catch (e, stack) {
      DALogger.error('DualPlayerEngine: Platform action failed: $action', e, stack);
      return PlaybackFailureResult(
        PlaybackFailure(
          message: 'Low-level platform exception during $action.',
          exception: e,
          stackTrace: stack,
        ),
      );
    }
  }

  void _cancelCrossfade() {
    _crossfadeTimer?.cancel();
    _crossfadeTimer = null;
    if (_isCrossfading) {
      _isCrossfading = false;
      _standbyBackend.stop();
      final targetVol = _isMuted ? 0.0 : _masterVolume;
      _activeBackend.setVolume(targetVol);
    }
  }

  void _handleBackendEvent(PlatformAudioBackend backend, PlatformAudioEvent event) {
    if (backend != _activeBackend) return;

    if (event is PlatformPlaybackCompleted) {
      if (!_isCrossfading) {
        next(isManual: false);
      }
    } else if (event is PlatformPlaybackError) {
      DALogger.warning('DualPlayerEngine: Platform playback error received. Skipping to next...');
      _cancelCrossfade();
      next(isManual: false);
    }
  }

  @override
  Future<PlaybackResult<void>> initialize() =>
      _runSafe('initialize', () async {
        unawaited(_backendA.initialize().catchError((e) {
          DALogger.error('DualPlayerEngine: Failed to initialize active backend', e);
        }));

        _standbyInitTimer = Timer(const Duration(seconds: 3), () async {
          try {
            await _backendB.initialize();
            DALogger.info('DualPlayerEngine: Standby backend B initialized successfully in background.');
          } catch (e) {
            DALogger.error('DualPlayerEngine: Failed to initialize standby backend', e);
          }
        });

        await _subA?.cancel();
        await _subB?.cancel();

        _subA = _backendA.eventStream.listen((e) => _handleBackendEvent(_backendA, e));
        _subB = _backendB.eventStream.listen((e) => _handleBackendEvent(_backendB, e));
      });

  @override
  Future<PlaybackResult<void>> dispose() =>
      _runSafe('dispose', () async {
        _cancelCrossfade();
        _standbyInitTimer?.cancel();
        _standbyInitTimer = null;
        await _subA?.cancel();
        await _subB?.cancel();
        _subA = null;
        _subB = null;
        await _queueController.close();
        await _backendA.dispose();
        await _backendB.dispose();
      });

  Future<String> _resolveAudioPath(Song song) async {
    final docDir = await getApplicationDocumentsDirectory();
    final localFile = File(p.join(docDir.path, 'da_tunes_downloads', '${song.id}.mp3'));
    if (localFile.existsSync()) {
      return localFile.path;
    }

    final tempDir = await getTemporaryDirectory();
    final cachedFile = File(p.join(tempDir.path, 'da_tunes_cache', '${song.id}.mp3'));
    if (cachedFile.existsSync()) {
      return cachedFile.path;
    }

    final stream = await _streamResolver.resolve(
      trackId: song.id,
      providerId: song.sourceId,
      songTitle: song.title,
      artist: song.artistId,
      duration: song.duration.value,
    );
    return stream.streamUrl;
  }

  int _playbackRequestId = 0;

  @override
  Future<PlaybackResult<void>> load(Song song) =>
      _runSafe('load', () async {
        _cancelCrossfade();
        final requestId = ++_playbackRequestId;
        _currentlyLoadingSongId = song.id;
        final targetSongId = song.id;

        await _activeBackend.stop();
        await _standbyBackend.stop();

        final audioPath = await _resolveAudioPath(song);
        if (_currentlyLoadingSongId != targetSongId || requestId != _playbackRequestId) {
          DALogger.info('DualPlayerEngine: load($targetSongId) discarded because request #$requestId was superseded by #$_playbackRequestId.');
          return;
        }

        final targetVol = _isMuted ? 0.0 : _masterVolume;
        await _activeBackend.load(audioPath);
        if (requestId != _playbackRequestId) {
          await _activeBackend.stop();
          return;
        }
        await _activeBackend.setVolume(targetVol);
      });

  @override
  Future<PlaybackResult<void>> play() =>
      _runSafe('play', () => _activeBackend.play());

  @override
  Future<PlaybackResult<void>> pause() =>
      _runSafe('pause', () async {
        _cancelCrossfade();
        await _activeBackend.pause();
      });

  @override
  Future<PlaybackResult<void>> resume() =>
      _runSafe('resume', () => play());

  @override
  Future<PlaybackResult<void>> stop() =>
      _runSafe('stop', () async {
        _playbackRequestId++;
        _cancelCrossfade();
        await _activeBackend.stop();
        await _standbyBackend.stop();
      });

  @override
  Future<PlaybackResult<void>> seek(Duration position) =>
      _runSafe('seek', () async {
        _cancelCrossfade();
        await _activeBackend.seek(position);
      });

  @override
  Future<PlaybackResult<void>> setVolume(double volume) =>
      _runSafe('setVolume', () async {
        _masterVolume = volume;
        final targetVol = _isMuted ? 0.0 : _masterVolume;
        if (!_isCrossfading) {
          await _activeBackend.setVolume(targetVol);
        }
      });

  @override
  Future<PlaybackResult<void>> mute() =>
      _runSafe('mute', () async {
        _isMuted = true;
        await _activeBackend.mute();
        await _standbyBackend.mute();
      });

  @override
  Future<PlaybackResult<void>> unmute() =>
      _runSafe('unmute', () async {
        _isMuted = false;
        final targetVol = _masterVolume;
        if (!_isCrossfading) {
          await _activeBackend.setVolume(targetVol);
        }
      });

  @override
  Stream<Queue> get onQueueChanged => _queueController.stream;

  @override
  Future<PlaybackResult<void>> next({bool isManual = true}) =>
      _runSafe('next', () async {
        final queue = _queue;
        if (queue == null || queue.songs.isEmpty) return;

        int nextIndex = queue.currentIndex;

        if (!isManual && queue.repeatMode == RepeatMode.one) {
          final loadResult = await load(queue.songs[queue.currentIndex]);
          if (loadResult is PlaybackFailureResult) {
            await next(isManual: false);
            return;
          }
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

        final crossEnabled = isCrossfadeEnabled?.call() ?? false;
        final crossDuration = getCrossfadeDuration?.call() ?? 0;
        final isPlaying = _activeBackend.currentState == 'playing';

        if (crossEnabled && crossDuration > 0 && isPlaying && !_isCrossfading) {
          await _startDualCrossfade(nextIndex, crossDuration);
        } else {
          _cancelCrossfade();
          _queue = queue.copyWith(currentIndex: nextIndex);
          _queueController.add(_queue!);
          final loadResult = await load(_queue!.songs[nextIndex]);
          if (loadResult is PlaybackFailureResult) {
            await next(isManual: false);
            return;
          }
          await play();
        }
      });

  Future<void> _startDualCrossfade(int nextIndex, int durationSecs) async {
    final queue = _queue;
    if (queue == null || nextIndex < 0 || nextIndex >= queue.songs.length) return;

    final requestId = ++_playbackRequestId;
    final incomingSong = queue.songs[nextIndex];
    final targetMasterVol = _isMuted ? 0.0 : _masterVolume;

    try {
      final audioPath = await _resolveAudioPath(incomingSong);
      if (requestId != _playbackRequestId) {
        DALogger.info('DualPlayerEngine: Dual crossfade pre-load for track ${incomingSong.id} discarded because request #$requestId was superseded by #$_playbackRequestId.');
        return;
      }

      if (_activeBackend.currentState != 'playing') {
        await _standbyBackend.stop();
        _cancelCrossfade();
        _queue = queue.copyWith(currentIndex: nextIndex);
        _queueController.add(_queue!);
        final loadResult = await load(queue.songs[nextIndex]);
        if (loadResult is PlaybackFailureResult) {
          await next(isManual: false);
          return;
        }
        await play();
        return;
      }

      await _standbyBackend.stop();
      await _standbyBackend.load(audioPath);
      if (requestId != _playbackRequestId) {
        await _standbyBackend.stop();
        return;
      }

      await _standbyBackend.setVolume(0.0);
      await _standbyBackend.play();

      _isCrossfading = true;
      _queue = queue.copyWith(currentIndex: nextIndex);
      _queueController.add(_queue!);

      final totalMs = durationSecs * 1000;
      final stepMs = 50;
      final totalSteps = totalMs ~/ stepMs;
      int currentStep = 0;

      _crossfadeTimer?.cancel();
      _crossfadeTimer = Timer.periodic(Duration(milliseconds: stepMs), (timer) async {
        if (requestId != _playbackRequestId) {
          timer.cancel();
          _crossfadeTimer = null;
          _isCrossfading = false;
          await _standbyBackend.stop();
          return;
        }

        currentStep++;
        final progress = (currentStep / totalSteps).clamp(0.0, 1.0);

        final activeVol = targetMasterVol * (1.0 - progress);
        final standbyVol = targetMasterVol * progress;

        await _activeBackend.setVolume(activeVol);
        await _standbyBackend.setVolume(standbyVol);

        if (progress >= 1.0) {
          timer.cancel();
          _crossfadeTimer = null;

          await _activeBackend.stop();
          final swapTemp = _activeBackend;
          _activeBackend = _standbyBackend;
          _standbyBackend = swapTemp;

          _isCrossfading = false;
        }
      });
    } catch (e) {
      if (requestId != _playbackRequestId) return;
      DALogger.warning('DualPlayerEngine: Dual crossfade pre-load failed: $e. Falling back to single switch.');
      _cancelCrossfade();
      _queue = queue.copyWith(currentIndex: nextIndex);
      _queueController.add(_queue!);
      await load(queue.songs[nextIndex]);
      await play();
    }
  }

  @override
  Future<PlaybackResult<void>> previous() =>
      _runSafe('previous', () async {
        _cancelCrossfade();
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
        await _activeBackend.setLoopMode(mode == RepeatMode.one);
        await _standbyBackend.setLoopMode(mode == RepeatMode.one);
        if (_queue != null) {
          _queue = _queue!.copyWith(repeatMode: mode);
          _queueController.add(_queue!);
        }
      });

  @override
  Future<PlaybackResult<void>> setShuffle(bool enabled) =>
      _runSafe('setShuffle', () async {
        await _activeBackend.setShuffle(enabled);
        await _standbyBackend.setShuffle(enabled);
        if (_queue != null) {
          _queue = _queue!.copyWith(shuffleEnabled: enabled);
          _updateShuffleIndices();
          _queueController.add(_queue!);
        }
      });

  @override
  Future<PlaybackResult<void>> playQueue(Queue queue) =>
      _runSafe('playQueue', () async {
        _cancelCrossfade();
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
        _cancelCrossfade();
        _masterVolume = session.volume;
        await _activeBackend.setVolume(session.volume);
        await _activeBackend.setSpeed(session.playbackSpeed);
        if (session.currentSong != null) {
          await load(session.currentSong!);
          await _activeBackend.seek(session.position);
        }
      });

  @override
  Duration get currentPosition => _isCrossfading ? _standbyBackend.currentPosition : _activeBackend.currentPosition;

  @override
  Duration get duration => _isCrossfading ? _standbyBackend.duration : _activeBackend.duration;

  @override
  Duration get bufferedPosition => _isCrossfading ? _standbyBackend.bufferedPosition : _activeBackend.bufferedPosition;
}
