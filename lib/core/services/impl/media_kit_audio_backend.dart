import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../platform_audio_backend.dart';
import '../logger_service.dart';
import '../stream_resolver.dart';
import '../../../app/router/router.dart';

/// MediaKit client-side implementation of PlatformAudioBackend wrapping the media_kit engine.
class MediaKitAudioBackend implements PlatformAudioBackend {
  Player? _player;
  final StreamController<PlatformAudioEvent> _eventController = StreamController<PlatformAudioEvent>.broadcast();

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffered = Duration.zero;
  double _volume = 1.0;
  double _speed = 1.0;
  String _state = 'idle';

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _bufferSub;
  StreamSubscription? _playingSub;
  StreamSubscription? _bufferingSub;
  StreamSubscription? _completedSub;
  StreamSubscription? _errorSub;

  int _backendLoadTicket = 0;
  bool _isInit = false;

  MediaKitAudioBackend();

  @override
  Future<void> initialize() async {
    if (_isInit) return;
    _isInit = true;
    DALogger.info('MediaKitAudioBackend: Initializing Player engine...');
    _state = 'ready';
    _eventController.add(const PlatformEngineInitialized());
  }

  Future<void> _ensurePlayerInitialized() async {
    if (_player != null) return;
    DALogger.info('MediaKitAudioBackend: Lazily initializing Player...');
    MediaKit.ensureInitialized();
    final p = Player();
    _player = p;
    _setupListeners();
    await p.setVolume(_volume * 100.0);
    await p.setRate(_speed);
  }

  void _setupListeners() {
    final p = _player;
    if (p == null) return;
    _posSub = p.stream.position.listen((p) {
      _position = p;
    });
    _durSub = p.stream.duration.listen((d) {
      _duration = d;
    });
    _bufferSub = p.stream.buffer.listen((b) {
      _buffered = b;
    });
    _playingSub = p.stream.playing.listen((isPlaying) {
      _state = isPlaying ? 'playing' : 'paused';
      DALogger.info('MediaKitAudioBackend: State changed to: ${_state.toUpperCase()}');
      if (isPlaying) {
        _eventController.add(const PlatformPlaybackStarted());
      } else {
        _eventController.add(const PlatformPlaybackPaused());
      }
    });
    _bufferingSub = p.stream.buffering.listen((isBuffering) {
      if (isBuffering) {
        _eventController.add(const PlatformBufferingStarted());
      } else {
        _eventController.add(const PlatformBufferingFinished());
      }
    });
    _completedSub = p.stream.completed.listen((isCompleted) {
      if (isCompleted) {
        _state = 'completed';
        _eventController.add(const PlatformPlaybackCompleted());
      }
    });
    _errorSub = p.stream.error.listen((err) {
      final song = StreamResolver.lastResolvedSong;
      final title = song?.title ?? "Unknown Title";

      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot play "$title": Playback error.'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        });
      }

      _eventController.add(PlatformPlaybackError(err.toString()));
    });
  }

  @override
  Future<void> dispose() async {
    DALogger.info('MediaKitAudioBackend: Disposing Player engine...');
    await _posSub?.cancel();
    await _durSub?.cancel();
    await _bufferSub?.cancel();
    await _playingSub?.cancel();
    await _bufferingSub?.cancel();
    await _completedSub?.cancel();
    await _errorSub?.cancel();
    final p = _player;
    if (p != null) {
      await p.dispose();
    }
    _state = 'disposed';
    if (!_eventController.isClosed) {
      _eventController.add(const PlatformEngineDisposed());
      _eventController.close();
    }
  }

  @override
  Future<void> load(String url) async {
    await _ensurePlayerInitialized();
    final ticket = ++_backendLoadTicket;
    DALogger.info('MediaKitAudioBackend: Loading streaming URL: "$url" (ticket: $ticket)');
    _state = 'loading';
    DALogger.info('MediaKitAudioBackend: State changed to: LOADING');
    _position = Duration.zero;
    _duration = Duration.zero;
    _buffered = Duration.zero;
    _eventController.add(const PlatformBufferingStarted());
    try {
      final p = _player;
      if (p != null) {
        await p.open(Media(url), play: false);
      }
      if (ticket != _backendLoadTicket) {
        DALogger.info('MediaKitAudioBackend: Discarding finished load for ticket #$ticket because superseded by #$_backendLoadTicket');
        final p = _player;
        if (p != null) {
          await p.stop();
        }
        return;
      }
    } catch (e) {
      if (ticket != _backendLoadTicket) return;
      final song = StreamResolver.lastResolvedSong;
      final title = song?.title ?? "Unknown Title";

      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot play "$title": Audio backend failed to load URL.'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        });
      }
      rethrow;
    }
    _state = 'ready';
    DALogger.info('MediaKitAudioBackend: State changed to: READY');
    _eventController.add(const PlatformBufferingFinished());
  }

  @override
  Future<void> play() async {
    DALogger.info('MediaKitAudioBackend: Start playback.');
    await _ensurePlayerInitialized();
    try {
      final p = _player;
      if (p != null) {
        await p.setVolume(_volume * 100.0);
        await p.play();
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    DALogger.info('MediaKitAudioBackend: Pause playback.');
    final p = _player;
    if (p != null) {
      await p.pause();
    }
  }

  @override
  Future<void> resume() async {
    DALogger.info('MediaKitAudioBackend: Resume playback.');
    await _ensurePlayerInitialized();
    try {
      final p = _player;
      if (p != null) {
        await p.setVolume(_volume * 100.0);
        await p.play();
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    _backendLoadTicket++;
    DALogger.info('MediaKitAudioBackend: Stop playback.');
    final p = _player;
    if (p != null) {
      await p.stop();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    DALogger.info('MediaKitAudioBackend: Seek to position ${position.inSeconds}s');
    final p = _player;
    if (p != null) {
      await p.seek(position);
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
    final p = _player;
    if (p != null) {
      await p.setVolume(volume * 100.0);
    }
    _eventController.add(PlatformVolumeChanged(volume));
  }

  @override
  Future<void> mute() async {
    final p = _player;
    if (p != null) {
      await p.setVolume(0.0);
    }
    _eventController.add(const PlatformVolumeChanged(0.0));
  }

  @override
  Future<void> unmute() async {
    final p = _player;
    if (p != null) {
      await p.setVolume(_volume * 100.0);
    }
    _eventController.add(PlatformVolumeChanged(_volume));
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    final p = _player;
    if (p != null) {
      await p.setRate(speed);
    }
    _eventController.add(PlatformSpeedChanged(speed));
  }

  @override
  Future<void> setLoopMode(bool enabled) async {
    final p = _player;
    if (p != null) {
      await p.setPlaylistMode(enabled ? PlaylistMode.loop : PlaylistMode.none);
    }
  }

  @override
  Future<void> setShuffle(bool enabled) async {}

  @override
  Duration get currentPosition => _position;

  @override
  Duration get duration => _duration;

  @override
  Duration get bufferedPosition => _buffered;

  @override
  double get speed => _speed;

  @override
  String get currentState => _state;

  @override
  Stream<PlatformAudioEvent> get eventStream => _eventController.stream;
}
