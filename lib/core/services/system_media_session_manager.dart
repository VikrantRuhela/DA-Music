import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'playback_controller.dart';
import '../../shared/models/music_models.dart';
import '../../shared/models/playback_state.dart' as clean;
import 'logger_service.dart';

/// Global reference to bridge audio_service callbacks back to the controller.
class SystemMediaSessionManager {
  static PlaybackController? controller;
  static MyAudioHandler? _audioHandler;
  static StreamSubscription? _controllerSubscription;
  static Timer? _positionTimer;

  static Future<void> initialize(PlaybackController playbackController) async {
    controller = playbackController;

    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isWindows) return;

    try {
      DALogger.info('SystemMediaSessionManager: Initializing AudioService...');
      _audioHandler = await AudioService.init(
        builder: () => MyAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.da_music.channel.audio',
          androidNotificationChannelName: 'Music Playback',
          androidNotificationOngoing: true,
          androidShowNotificationBadge: true,
          androidNotificationIcon: 'drawable/ic_notification',
        ),
      );
      _setupStateListener();
    } catch (e, stack) {
      DALogger.error('SystemMediaSessionManager: Initialization failed', e, stack);
    }
  }

  static void _setupStateListener() {
    _controllerSubscription?.cancel();
    final c = controller;
    if (c == null) return;

    // Listen to changes on PlaybackController
    c.addListener(_onControllerStateChanged);
    _onControllerStateChanged(); // update immediately with current state

    // Set up a timer to sync play position smoothly
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final activeController = controller;
      if (activeController == null) return;

      final position = activeController.position;
      final song = activeController.currentSong;
      final isPlaying = activeController.status == clean.PlaybackStatus.playing;

      if (song != null && _audioHandler != null) {
        _audioHandler!.updatePlaybackPosition(position, isPlaying);
      }
    });
  }

  static void _onControllerStateChanged() {
    final c = controller;
    if (c == null) return;

    final song = c.currentSong;
    final isPlaying = c.status == clean.PlaybackStatus.playing;
    final isBuffering = c.status == clean.PlaybackStatus.buffering;

    if (song != null && _audioHandler != null) {
      final duration = song.duration;
      final position = c.position;

      _audioHandler!.updateMetadata(song, duration);
      _audioHandler!.updatePlaybackState(isPlaying, isBuffering, position);
    } else if (_audioHandler != null) {
      // Stopped / Idle
      _audioHandler!.playbackState.add(_audioHandler!.playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
        speed: 0.0,
      ));
    }
  }

  static void dispose() {
    _positionTimer?.cancel();
    _controllerSubscription?.cancel();
    controller?.removeListener(_onControllerStateChanged);
  }
}

/// Audio Handler implementation for audio_service.
class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  MyAudioHandler() {
    // Emit initial empty state
    playbackState.add(PlaybackState(
      controls: const [],
      systemActions: const {
        MediaAction.seek,
        MediaAction.playPause,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0],
      processingState: AudioProcessingState.idle,
      playing: false,
      speed: 0.0,
    ));
  }

  void updateMetadata(Song song, Duration duration) {
    Uri? resolvedArtUri;

    if (song.artworkUrl != null && song.artworkUrl!.isNotEmpty) {
      if (song.artworkUrl!.startsWith('http')) {
        resolvedArtUri = Uri.tryParse(song.artworkUrl!);
      } else {
        final file = File(song.artworkUrl!);
        if (file.existsSync()) {
          resolvedArtUri = Uri.file(song.artworkUrl!);
        }
      }
    }

    if (resolvedArtUri == null && song.source == 'local') {
      try {
        final audioFile = File(song.id);
        if (audioFile.existsSync()) {
          final parentDir = audioFile.parent;
          if (parentDir.existsSync()) {
            final commonNames = [
              'cover.jpg', 'cover.png', 'cover.jpeg',
              'folder.jpg', 'folder.png', 'folder.jpeg',
              'albumart.jpg', 'albumart.png', 'albumart.jpeg',
              'album.jpg', 'album.png', 'album.jpeg',
              'art.jpg', 'art.png', 'art.jpeg',
            ];

            File? foundFile;
            for (final name in commonNames) {
              final f = File('${parentDir.path}/$name');
              if (f.existsSync()) {
                foundFile = f;
                break;
              }
            }

            if (foundFile == null) {
              final list = parentDir.listSync();
              for (final entity in list) {
                if (entity is File) {
                  final filename = entity.path.split('/').last.split('\\').last.toLowerCase();
                  final ext = filename.split('.').last;
                  if (ext == 'jpg' || ext == 'png' || ext == 'jpeg') {
                    if (filename.contains('cover') ||
                        filename.contains('folder') ||
                        filename.contains('albumart') ||
                        filename.contains('album') ||
                        filename.contains('art')) {
                      foundFile = entity;
                      break;
                    }
                  }
                }
              }
            }

            if (foundFile != null) {
              resolvedArtUri = Uri.file(foundFile.path);
            }
          }
        }
      } catch (_) {}
    }

    if (resolvedArtUri == null && !kIsWeb && Platform.isAndroid) {
      resolvedArtUri = Uri.parse('android.resource://com.damusic.da_music/drawable/ic_notification');
    }

    mediaItem.add(MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: duration,
      artUri: resolvedArtUri,
    ));
  }

  void updatePlaybackState(bool isPlaying, bool isBuffering, Duration position) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (isPlaying) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.playPause,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: isBuffering ? AudioProcessingState.buffering : AudioProcessingState.ready,
      playing: isPlaying,
      updatePosition: position,
      speed: isPlaying ? 1.0 : 0.0,
    ));
  }

  void updatePlaybackPosition(Duration position, bool isPlaying) {
    playbackState.add(playbackState.value.copyWith(
      updatePosition: position,
      playing: isPlaying,
      speed: isPlaying ? 1.0 : 0.0,
    ));
  }

  @override
  Future<void> play() async {
    SystemMediaSessionManager.controller?.play();
  }

  @override
  Future<void> pause() async {
    SystemMediaSessionManager.controller?.pause();
  }

  @override
  Future<void> stop() async {
    SystemMediaSessionManager.controller?.stop();
  }

  @override
  Future<void> skipToNext() async {
    SystemMediaSessionManager.controller?.next();
  }

  @override
  Future<void> skipToPrevious() async {
    SystemMediaSessionManager.controller?.previous();
  }

  @override
  Future<void> seek(Duration position) async {
    SystemMediaSessionManager.controller?.seek(position);
  }
}
