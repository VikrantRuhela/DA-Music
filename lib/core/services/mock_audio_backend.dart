import 'dart:async';
import 'audio_backend.dart';
import '../../shared/models/playback_state.dart';

class MockAudioBackend implements AudioBackend {
  final _positionController = StreamController<Duration>.broadcast();
  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _bufferController = StreamController<double>.broadcast();

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  PlaybackStatus _status = PlaybackStatus.idle;
  double _volume = 0.8;

  Timer? _tickTimer;
  Timer? _bufferTimer;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;

  @override
  Stream<double> get bufferProgressStream => _bufferController.stream;

  @override
  Duration get currentPosition => _currentPosition;

  @override
  double get volume => _volume;

  @override
  PlaybackStatus get currentStatus => _status;

  void _setStatus(PlaybackStatus status) {
    _status = status;
    _statusController.add(status);
  }

  @override
  Future<void> load(String source, Duration totalDuration) async {
    await stop();
    _totalDuration = totalDuration;
    _currentPosition = Duration.zero;
    _positionController.add(_currentPosition);

    _setStatus(PlaybackStatus.loading);
    _bufferController.add(0.0);

    // Simulate buffering progress
    int progressPercent = 0;
    _bufferTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      progressPercent += 20;
      if (progressPercent >= 100) {
        _bufferController.add(1.0);
        _setStatus(PlaybackStatus.paused);
        timer.cancel();
      } else {
        _bufferController.add(progressPercent / 100);
        if (progressPercent == 40) {
          _setStatus(PlaybackStatus.buffering);
        }
      }
    });
  }

  @override
  Future<void> play() async {
    if (_status == PlaybackStatus.playing || _totalDuration == Duration.zero) return;

    _setStatus(PlaybackStatus.playing);
    _tickTimer?.cancel();
    // 60 FPS update is ~16ms (1000ms / 60)
    _tickTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_status != PlaybackStatus.playing) {
        timer.cancel();
        return;
      }
      _currentPosition += const Duration(milliseconds: 16);
      if (_currentPosition >= _totalDuration) {
        _currentPosition = _totalDuration;
        _positionController.add(_currentPosition);
        _setStatus(PlaybackStatus.completed);
        timer.cancel();
      } else {
        _positionController.add(_currentPosition);
      }
    });
  }

  @override
  Future<void> pause() async {
    if (_status != PlaybackStatus.playing) return;
    _tickTimer?.cancel();
    _setStatus(PlaybackStatus.paused);
  }

  @override
  Future<void> stop() async {
    _tickTimer?.cancel();
    _bufferTimer?.cancel();
    _currentPosition = Duration.zero;
    _positionController.add(_currentPosition);
    _setStatus(PlaybackStatus.idle);
  }

  @override
  Future<void> seek(Duration position) async {
    Duration target = position;
    if (target < Duration.zero) target = Duration.zero;
    if (target > _totalDuration) target = _totalDuration;
    _currentPosition = target;
    _positionController.add(_currentPosition);
    if (_status == PlaybackStatus.completed && target < _totalDuration) {
      _setStatus(PlaybackStatus.paused);
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _positionController.close();
    await _statusController.close();
    await _bufferController.close();
  }
}
