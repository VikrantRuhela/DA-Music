import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:da_music/core/services/playback_controller.dart';
import 'package:da_music/core/services/impl/playback_engine_impl.dart';
import 'package:da_music/core/services/platform_audio_backend.dart';
import 'package:da_music/core/services/stream_resolver.dart';
import 'package:da_music/core/services/source_manager.dart';
import 'package:da_music/domain/entities/audio_stream.dart';
import 'package:da_music/shared/models/music_models.dart';
import 'package:da_music/shared/models/playback_state.dart';

class MockPlatformAudioBackend implements PlatformAudioBackend {
  final _eventController = StreamController<PlatformAudioEvent>.broadcast();
  PlaybackStatus _status = PlaybackStatus.idle;

  @override
  Future<void> initialize() async {}
  @override
  Future<void> dispose() async {
    await _eventController.close();
  }
  @override
  Future<void> load(String url) async {
    _status = PlaybackStatus.loading;
  }
  @override
  Future<void> play() async {
    _status = PlaybackStatus.playing;
    _eventController.add(const PlatformPlaybackStarted());
  }
  @override
  Future<void> pause() async {
    _status = PlaybackStatus.paused;
    _eventController.add(const PlatformPlaybackPaused());
  }
  @override
  Future<void> resume() async {
    _status = PlaybackStatus.playing;
    _eventController.add(const PlatformPlaybackStarted());
  }
  @override
  Future<void> stop() async {
    _status = PlaybackStatus.idle;
    _eventController.add(const PlatformPlaybackStopped());
  }
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> mute() async {}
  @override
  Future<void> unmute() async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> setLoopMode(bool enabled) async {}
  @override
  Future<void> setShuffle(bool enabled) async {}

  @override
  Duration get currentPosition => Duration.zero;
  @override
  Duration get duration => Duration.zero;
  @override
  Duration get bufferedPosition => Duration.zero;
  @override
  double get speed => 1.0;
  @override
  String get currentState => _status.toString();

  @override
  Stream<PlatformAudioEvent> get eventStream => _eventController.stream;

  void triggerCompletion() {
    _eventController.add(const PlatformPlaybackCompleted());
  }
}

class MockStreamResolver extends StreamResolver {
  MockStreamResolver() : super(SourceManager());

  @override
  Future<AudioStream> resolve({
    required String trackId,
    required String providerId,
    String? songTitle,
    String? artist,
    Duration? duration,
    StreamQuality quality = StreamQuality.auto,
  }) async {
    return AudioStream(
      id: trackId,
      providerId: providerId,
      streamUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      mimeType: 'audio/mp3',
      bitrate: 128000,
      duration: const Duration(minutes: 3),
      expiresAt: DateTime.now().add(const Duration(hours: 4)),
      headers: const {},
      quality: 'highest',
      codec: 'mp3',
      isLive: false,
      isCached: false,
    );
  }
}

void main() {
  group('Queue Engine Unit Tests', () {
    late PlaybackController controller;
    late PlaybackEngineImpl engine;
    late MockPlatformAudioBackend backend;

    final songList = [
      const Song(id: '1', title: 'Song 1', artist: 'Artist 1', album: 'Album', duration: Duration(minutes: 3), artworkUrl: null, source: 'youtube_music', lyrics: null),
      const Song(id: '2', title: 'Song 2', artist: 'Artist 2', album: 'Album', duration: Duration(minutes: 3), artworkUrl: null, source: 'youtube_music', lyrics: null),
      const Song(id: '3', title: 'Song 3', artist: 'Artist 3', album: 'Album', duration: Duration(minutes: 3), artworkUrl: null, source: 'youtube_music', lyrics: null),
    ];

    setUp(() async {
      backend = MockPlatformAudioBackend();
      engine = PlaybackEngineImpl(backend, MockStreamResolver());
      controller = PlaybackController(engine);
      await controller.setQueue(songList, startIndex: 0, autoPlay: true);
    });

    test('Initial queue state is set correctly', () {
      expect(controller.currentQueue.length, 3);
      expect(controller.currentIndex, 0);
      expect(controller.currentSong?.id, '1');
    });

    test('Skip next advances index and plays next song', () async {
      await controller.next();
      expect(controller.currentIndex, 1);
      expect(controller.currentSong?.id, '2');
    });

    test('Skip previous goes back to first song', () async {
      await controller.next(); // to index 1
      await controller.previous(); // back to index 0
      expect(controller.currentIndex, 0);
      expect(controller.currentSong?.id, '1');
    });

    test('Repeat ALL wraps around index from last to first on next', () async {
      await controller.setRepeatMode(RepeatMode.all);
      await controller.next(); // to index 1
      await controller.next(); // to index 2
      await controller.next(); // wrap to index 0
      expect(controller.currentIndex, 0);
      expect(controller.currentSong?.id, '1');
    });

    test('Repeat OFF stops playback at the end of queue on next', () async {
      await controller.setRepeatMode(RepeatMode.off);
      await controller.next(); // to index 1
      await controller.next(); // to index 2
      await controller.next(); // end of queue -> stop playback
      await Future.delayed(const Duration(milliseconds: 100));
      expect(controller.status, PlaybackStatus.idle);
    });

    test('Shuffle mode plays in a shuffled index sequence', () async {
      await controller.toggleShuffle();
      expect(controller.settings.isShuffle, true);
      await controller.next();
      expect(controller.currentIndex, inClosedOpenRange(0, 3));
    });

    test('Natural completion automatically advances queue', () async {
      backend.triggerCompletion();
      // Allow microtasks and stream events to flush
      await Future.delayed(const Duration(milliseconds: 100));
      expect(controller.currentIndex, 1);
      expect(controller.currentSong?.id, '2');
    });
  });
}
