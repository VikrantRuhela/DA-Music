import 'package:flutter/foundation.dart';
import 'dart:async';
import 'playback_engine.dart';
import 'playback_result.dart';
import 'playback_events.dart' as clean;
import 'logger_service.dart';
import 'source_manager.dart';
import 'youtube_music_adapter.dart';
import '../../domain/repositories/artist_repository.dart';
import '../../domain/repositories/album_repository.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../../domain/entities/song.dart' as domain;
import '../../domain/entities/repeat_mode.dart' as domain;
import '../../domain/entities/queue.dart' as domain;
import '../../domain/entities/value_objects.dart' as domain;
import '../../shared/models/music_models.dart';
import '../../shared/models/playback_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/taste_engine/presentation/providers/taste_engine_providers.dart';
import '../../features/taste_engine/domain/recommendation_engine.dart';
import '../../data/repositories/download_repository.dart';
import '../../shared/providers/library_providers.dart';

/// Central playback controller orchestrating queue, repeat modes and state transitions.
class PlaybackController extends ChangeNotifier {
  final PlaybackEngine _playbackEngine;
  final SourceManager? _sourceManager;
  final ArtistRepository? _artistRepository;
  final AlbumRepository? _albumRepository;
  final RecommendationRepository? _recommendationRepository;
  
  final StreamController<clean.PlaybackEvent> _eventController =
      StreamController<clean.PlaybackEvent>.broadcast();

  PlaybackStatus _status = PlaybackStatus.idle;
  Duration _currentPosition = Duration.zero;
  final double _bufferProgress = 0.0;
  PlayerSettings _settings = const PlayerSettings();
  int _lastVolume = 80;
  double _playbackSpeed = 1.0;
  Timer? _positionTimer;
  bool _isSeeking = false;
  Timer? _seekLockTimer;

  final List<Song> _queueSongs = [];
  int _currentIndex = -1;
  final Ref? _ref;
  bool _isGeneratingSmartQueue = false;
  bool _isAppendingAutoplay = false;

  PlaybackController(
    this._playbackEngine, [
    this._ref,
    this._sourceManager,
    this._artistRepository,
    this._albumRepository,
    this._recommendationRepository,
  ]) {
    _init();
  }

  bool get _isSmartQueueActive {
    if (_ref == null) return true;
    final state = _ref!.read(tasteEngineNotifierProvider);
    if (!state.isSmartQueueEnabled) return false;
    if (_settings.repeatMode != RepeatMode.off) return false;
    return true;
  }

  void _init() {
    _playbackEngine.initialize();
    _playbackEngine.onQueueChanged.listen((queue) {
      _queueSongs.clear();
      _queueSongs.addAll(queue.songs.map((s) => _mapFromDomain(s)));
      _currentIndex = queue.currentIndex;

      if (_currentIndex >= 0 && _currentIndex < _queueSongs.length) {
        _status = PlaybackStatus.playing;
        _startPositionTimer();

        // Check if we need to append autoplay recommendations!
        if ((_queueSongs.length - 1 - _currentIndex) <= 5) {
          _appendSmartAutoplayRecommendations();
        }
      } else {
        _status = PlaybackStatus.idle;
        _stopPositionTimer();
      }

      // Print the required event details
      final currentSongId = currentSong?.id ?? 'none';
      // ignore: avoid_print
      print('Queue changed:');
      // ignore: avoid_print
      print('- Current Index: $_currentIndex');
      // ignore: avoid_print
      print('- Current Song ID: $currentSongId');
      // ignore: avoid_print
      print('- Queue Length: ${_queueSongs.length}');
      // ignore: avoid_print
      print('- Repeat Mode: ${_settings.repeatMode}');
      // ignore: avoid_print
      print('- Shuffle State: ${_settings.isShuffle}');

      notifyListeners();
    });
  }

  // Getters
  Stream<clean.PlaybackEvent> get eventStream => _eventController.stream;
  List<QueueItem> get queue => _queueSongs
      .map((s) => QueueItem(id: s.id, song: s))
      .toList();
  List<Song> get currentQueue => _queueSongs;
  int get currentIndex => _currentIndex;
  Song? get currentSong {
    if (_currentIndex >= 0 && _currentIndex < _queueSongs.length) {
      return _queueSongs[_currentIndex];
    }
    return null;
  }
  PlaybackStatus get status => _status;
  Duration get position => _currentPosition;
  double get bufferProgress => _bufferProgress;
  PlayerSettings get settings => _settings;
  double get playbackSpeed => _playbackSpeed;

  // State Machine Validation
  bool _validateTransition(PlaybackStatus targetStatus) {
    DALogger.info('Transition attempt: $_status -> $targetStatus');
    if (_status == PlaybackStatus.idle && targetStatus == PlaybackStatus.paused) {
      DALogger.warning('Illegal state transition rejected: idle cannot transition to paused directly.');
      return false;
    }
    return true;
  }

  // Log wrapper
  Future<void> _runAction(String name, Future<PlaybackResult<void>> Function() action) async {
    final startTime = DateTime.now();
    DALogger.info('PlaybackController: Starting $name');
    final result = await action();
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    if (result is PlaybackSuccess) {
      DALogger.info('PlaybackController: Completed $name in ${duration}ms');
    } else if (result is PlaybackFailureResult) {
      final failure = result.failure;
      final originalEx = failure.originalException;
      // ignore: avoid_print
      print('PlaybackController: Failed $name');
      // ignore: avoid_print
      print('Original Exception Type: ${originalEx.runtimeType}');
      // ignore: avoid_print
      print('Original Exception Message: $originalEx');
      // ignore: avoid_print
      print('Complete Stack Trace:\n${failure.stackTrace ?? StackTrace.current}');
      DALogger.error('PlaybackController: Failed $name: ${failure.message}', originalEx, failure.stackTrace);
    }
  }

  // Actions
  Future<void> setQueue(List<Song> songs, {int startIndex = 0, bool autoPlay = true}) async {
    final copiedSongs = List<Song>.from(songs);
    
    if (_isSmartQueueActive && copiedSongs.isNotEmpty) {
      final seedSong = copiedSongs[startIndex];
      _queueSongs.clear();
      _queueSongs.add(seedSong);
      _currentIndex = 0;

      final domainQueue = domain.Queue(
        songs: _queueSongs.map((s) => _mapToDomain(s)).toList(),
        currentIndex: _currentIndex,
        repeatMode: _mapRepeatToDomain(_settings.repeatMode),
        shuffleEnabled: _settings.isShuffle,
      );

      _eventController.add(clean.QueueChanged(domainQueue));
      notifyListeners();

      await _runAction('playQueue', () => _playbackEngine.playQueue(domainQueue));
      
      _generateSmartAutoQueue(seedSong);
    } else {
      _queueSongs.clear();
      _queueSongs.addAll(copiedSongs);
      _currentIndex = copiedSongs.isEmpty ? -1 : startIndex.clamp(0, copiedSongs.length - 1);

      final domainQueue = domain.Queue(
        songs: _queueSongs.map((s) => _mapToDomain(s)).toList(),
        currentIndex: _currentIndex,
        repeatMode: _mapRepeatToDomain(_settings.repeatMode),
        shuffleEnabled: _settings.isShuffle,
      );

      _eventController.add(clean.QueueChanged(domainQueue));
      notifyListeners();

      await _runAction('playQueue', () => _playbackEngine.playQueue(domainQueue));
    }
  }

  Future<void> selectSong(Song song) async {
    DALogger.info('PlaybackController: selectSong "${song.title}"');
    await setQueue([song], autoPlay: true);
    _generateSmartAutoQueue(song);
  }

  Future<void> reorderQueue(List<Song> songs, int newCurrentIndex) async {
    _queueSongs.clear();
    _queueSongs.addAll(songs);
    _currentIndex = newCurrentIndex.clamp(-1, songs.length - 1);

    final domainQueue = domain.Queue(
      songs: _queueSongs.map((s) => _mapToDomain(s)).toList(),
      currentIndex: _currentIndex,
      repeatMode: _mapRepeatToDomain(_settings.repeatMode),
      shuffleEnabled: _settings.isShuffle,
    );

    _eventController.add(clean.QueueChanged(domainQueue));
    notifyListeners();

    await _runAction('playQueue', () => _playbackEngine.playQueue(domainQueue));
  }

  Future<void> _generateSmartAutoQueue(Song song) async {
    if (!_isSmartQueueActive) return;
    if (_isGeneratingSmartQueue) return;
    _isGeneratingSmartQueue = true;

    DALogger.info('PlaybackController: Generating Smart Auto Queue for "${song.title}"');

    try {
      final ref = _ref;
      if (ref == null) {
        _isGeneratingSmartQueue = false;
        return;
      }

      final tasteState = ref.read(tasteEngineNotifierProvider);
      final downloadRepo = ref.read(downloadRepositoryProvider);
      final libraryManager = ref.read(libraryManagerProvider);

      final downloadedList = await downloadRepo.getDownloadedSongs();
      final likedList = libraryManager.likedSongs;

      final List<Song> recentlyPlayed = [];
      for (final log in tasteState.logs.reversed) {
        final id = log['songId'] as String? ?? '';
        if (id.isEmpty || id == 'search_query') continue;
        recentlyPlayed.add(Song(
          id: id,
          title: log['songTitle'] ?? '',
          artist: log['artist'] ?? '',
          album: log['album'] ?? '',
          duration: Duration(milliseconds: log['durationMs'] ?? 0),
          artworkUrl: log['artworkUrl'] ?? '',
          source: log['source'] ?? 'youtube_music',
          lyrics: null,
        ));
        if (recentlyPlayed.length >= 20) break;
      }

      final candidates = await RecommendationEngine.generateSmartQueue(
        seedSong: song,
        dna: tasteState.dna,
        sourceManager: _sourceManager!,
        downloadedSongs: downloadedList,
        likedSongs: likedList,
        recentlyPlayedSongs: recentlyPlayed,
      );

      if (candidates.isNotEmpty) {
        final List<Song> newQueue = [song, ...candidates];
        
        _queueSongs.clear();
        _queueSongs.addAll(newQueue);
        _currentIndex = 0;

        final domainQueue = domain.Queue(
          songs: _queueSongs.map((s) => _mapToDomain(s)).toList(),
          currentIndex: _currentIndex,
          repeatMode: _mapRepeatToDomain(_settings.repeatMode),
          shuffleEnabled: _settings.isShuffle,
        );

        _eventController.add(clean.QueueChanged(domainQueue));
        notifyListeners();
        await _runAction('playQueue', () => _playbackEngine.playQueue(domainQueue));
      }
    } catch (e, stack) {
      DALogger.error('SmartAutoQueue generation failed', e, stack);
    } finally {
      _isGeneratingSmartQueue = false;
    }
  }

  Future<void> _appendSmartAutoplayRecommendations() async {
    if (!_isSmartQueueActive) return;
    if (_isAppendingAutoplay) return;
    _isAppendingAutoplay = true;

    final current = currentSong;
    if (current == null) {
      _isAppendingAutoplay = false;
      return;
    }

    DALogger.info('PlaybackController: Nearing end of queue. Fetching autoplay recommendations based on "${current.title}"...');

    try {
      final ref = _ref;
      if (ref == null) {
        _isAppendingAutoplay = false;
        return;
      }

      final tasteState = ref.read(tasteEngineNotifierProvider);
      final downloadRepo = ref.read(downloadRepositoryProvider);
      final libraryManager = ref.read(libraryManagerProvider);

      final downloadedList = await downloadRepo.getDownloadedSongs();
      final likedList = libraryManager.likedSongs;

      final List<Song> recentlyPlayed = [];
      for (final log in tasteState.logs.reversed) {
        final id = log['songId'] as String? ?? '';
        if (id.isEmpty || id == 'search_query') continue;
        recentlyPlayed.add(Song(
          id: id,
          title: log['songTitle'] ?? '',
          artist: log['artist'] ?? '',
          album: log['album'] ?? '',
          duration: Duration(milliseconds: log['durationMs'] ?? 0),
          artworkUrl: log['artworkUrl'] ?? '',
          source: log['source'] ?? 'youtube_music',
          lyrics: null,
        ));
        if (recentlyPlayed.length >= 20) break;
      }

      final candidates = await RecommendationEngine.generateSmartQueue(
        seedSong: current,
        dna: tasteState.dna,
        sourceManager: _sourceManager!,
        downloadedSongs: downloadedList,
        likedSongs: likedList,
        recentlyPlayedSongs: recentlyPlayed,
      );

      final Set<String> alreadyQueuedIds = _queueSongs.map((s) => s.id).toSet();
      final List<Song> newCandidates = candidates.where((s) => !alreadyQueuedIds.contains(s.id)).toList();

      if (newCandidates.isNotEmpty) {
        DALogger.info('PlaybackController: Appending ${newCandidates.length} new autoplay tracks to queue.');
        
        _queueSongs.addAll(newCandidates);

        final domainQueue = domain.Queue(
          songs: _queueSongs.map((s) => _mapToDomain(s)).toList(),
          currentIndex: _currentIndex,
          repeatMode: _mapRepeatToDomain(_settings.repeatMode),
          shuffleEnabled: _settings.isShuffle,
        );

        _eventController.add(clean.QueueChanged(domainQueue));
        notifyListeners();
        await _runAction('playQueue', () => _playbackEngine.playQueue(domainQueue));
      }
    } catch (e, stack) {
      DALogger.error('Autoplay recommendations append failed', e, stack);
    } finally {
      _isAppendingAutoplay = false;
    }
  }

  Future<void> playNext(Song song) async {
    final existingIndex = _queueSongs.indexWhere((s) => s.id == song.id);
    if (existingIndex >= 0) {
      _queueSongs.removeAt(existingIndex);
      if (existingIndex < _currentIndex) {
        _currentIndex--;
      }
    }

    if (_queueSongs.isEmpty) {
      await setQueue([song], startIndex: 0, autoPlay: true);
    } else {
      final insertIndex = _currentIndex + 1;
      _queueSongs.insert(insertIndex, song);
      // Update queue on the engine and keep current song playing
      final domainQueue = domain.Queue(
        songs: _queueSongs.map((s) => _mapToDomain(s)).toList(),
        currentIndex: _currentIndex,
        repeatMode: _mapRepeatToDomain(_settings.repeatMode),
        shuffleEnabled: _settings.isShuffle,
      );
      _eventController.add(clean.QueueChanged(domainQueue));
      notifyListeners();
      await _runAction('playQueue', () => _playbackEngine.playQueue(domainQueue));
    }
  }

  Future<void> addToQueue(Song song) async {
    final existingIndex = _queueSongs.indexWhere((s) => s.id == song.id);
    if (existingIndex >= 0) {
      _queueSongs.removeAt(existingIndex);
      if (existingIndex < _currentIndex) {
        _currentIndex--;
      }
    }

    if (_queueSongs.isEmpty) {
      await setQueue([song], startIndex: 0, autoPlay: true);
    } else {
      _queueSongs.add(song);
      final domainQueue = domain.Queue(
        songs: _queueSongs.map((s) => _mapToDomain(s)).toList(),
        currentIndex: _currentIndex,
        repeatMode: _mapRepeatToDomain(_settings.repeatMode),
        shuffleEnabled: _settings.isShuffle,
      );
      _eventController.add(clean.QueueChanged(domainQueue));
      notifyListeners();
      await _runAction('playQueue', () => _playbackEngine.playQueue(domainQueue));
    }
  }



  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_status == PlaybackStatus.playing) {
        if (!_isSeeking) {
          _currentPosition = _playbackEngine.currentPosition;
          notifyListeners();
        }
      } else {
        _positionTimer?.cancel();
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> play() async {
    if (currentSong == null) return;
    if (_validateTransition(PlaybackStatus.playing)) {
      _status = PlaybackStatus.playing;
      notifyListeners();
      _startPositionTimer();

      await _runAction('play', () => _playbackEngine.play());
      _eventController.add(clean.PlaybackStarted(_mapToDomain(currentSong!)));
    }
  }

  Future<void> pause() async {
    if (_validateTransition(PlaybackStatus.paused)) {
      _status = PlaybackStatus.paused;
      notifyListeners();
      _stopPositionTimer();

      await _runAction('pause', () => _playbackEngine.pause());
      _eventController.add(const clean.PlaybackPaused());
    }
  }

  Future<void> resume() async {
    await play();
    _eventController.add(const clean.PlaybackResumed());
  }

  Future<void> stop() async {
    if (_validateTransition(PlaybackStatus.idle)) {
      _status = PlaybackStatus.idle;
      notifyListeners();
      _stopPositionTimer();

      await _runAction('stop', () => _playbackEngine.stop());
      _eventController.add(const clean.PlaybackStopped());
    }
  }

  Future<void> seek(Duration position) async {
    _seekLockTimer?.cancel();
    _isSeeking = true;
    _currentPosition = position;
    _eventController.add(clean.PositionChanged(position));
    notifyListeners();

    await _runAction('seek', () => _playbackEngine.seek(position));

    _seekLockTimer = Timer(const Duration(milliseconds: 300), () {
      _isSeeking = false;
    });
  }

  Future<void> next() async {
    await _runAction('next', () => _playbackEngine.next());
  }

  Future<void> previous() async {
    await _runAction('previous', () => _playbackEngine.previous());
  }

  Future<void> toggleShuffle() async {
    final shuffleState = !_settings.isShuffle;
    _settings = _settings.copyWith(isShuffle: shuffleState);
    await _runAction('setShuffle', () => _playbackEngine.setShuffle(shuffleState));
    _eventController.add(clean.ShuffleChanged(shuffleState));
    notifyListeners();
  }

  Future<void> setRepeatMode(RepeatMode mode) async {
    _settings = _settings.copyWith(repeatMode: mode);
    final domainMode = _mapRepeatToDomain(mode);
    await _runAction('setRepeatMode', () => _playbackEngine.setRepeatMode(domainMode));
    _eventController.add(clean.RepeatChanged(domainMode));
    notifyListeners();
  }

  Future<void> setVolume(int val) async {
    final double volumeRatio = val.clamp(0, 100) / 100.0;
    await _runAction('setVolume', () => _playbackEngine.setVolume(volumeRatio));
    _settings = _settings.copyWith(
      volume: val,
      isMuted: val == 0,
    );
    _eventController.add(clean.VolumeChanged(volumeRatio));
    notifyListeners();
  }

  Future<void> toggleMute() async {
    final isMuted = !_settings.isMuted;
    if (isMuted) {
      _lastVolume = _settings.volume;
      await setVolume(0);
    } else {
      await setVolume(_lastVolume);
    }
  }

  // Speed adjustments
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    DALogger.info('Playback speed adjusted: ${speed}x');
    notifyListeners();
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _playbackEngine.dispose();
    _eventController.close();
    super.dispose();
  }

  // Mapping Helpers
  domain.Song _mapToDomain(Song song) {
    return domain.Song(
      id: song.id,
      title: song.title,
      artistId: song.artist,
      albumId: song.album,
      duration: domain.DurationValue(song.duration),
      thumbnail: domain.Artwork(song.artworkUrl),
      artwork: domain.Artwork(song.artworkUrl),
      sourceId: song.source,
    );
  }

  domain.RepeatMode _mapRepeatToDomain(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.one:
        return domain.RepeatMode.one;
      case RepeatMode.all:
        return domain.RepeatMode.all;
      default:
        return domain.RepeatMode.none;
    }
  }

  Song _mapFromDomain(domain.Song s) {
    String cleanAlbum = s.albumId;
    if (cleanAlbum == 'yt_album_unknown' ||
        cleanAlbum.trim().isEmpty ||
        cleanAlbum.startsWith('MPREb_') ||
        cleanAlbum.startsWith('OLAK5uy_') ||
        cleanAlbum.startsWith('PL') ||
        cleanAlbum.startsWith('RD') ||
        cleanAlbum.startsWith('VL')) {
      cleanAlbum = 'Single';
    }
    return Song(
      id: s.id,
      title: s.title,
      artist: s.artistId,
      album: cleanAlbum,
      duration: s.duration.value,
      artworkUrl: s.artwork.url,
      source: s.sourceId,
      lyrics: null,
    );
  }
}

