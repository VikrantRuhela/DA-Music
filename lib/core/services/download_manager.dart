import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../shared/models/music_models.dart';

enum DownloadStatus { queued, downloading, paused, completed, failed, cancelled }

class DownloadTask {
  final String songId;
  final String title;
  final String artist;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final String? localFilePath;
  final String? error;

  const DownloadTask({
    required this.songId,
    required this.title,
    required this.artist,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.localFilePath,
    this.error,
  });

  DownloadTask copyWith({
    DownloadStatus? status,
    double? progress,
    String? localFilePath,
    String? error,
  }) {
    return DownloadTask(
      songId: songId,
      title: title,
      artist: artist,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      localFilePath: localFilePath ?? this.localFilePath,
      error: error ?? this.error,
    );
  }
}

class DownloadManager extends ChangeNotifier {
  final Map<String, DownloadTask> _tasks = {};
  final Map<String, Timer?> _timers = {};

  List<DownloadTask> get allTasks => _tasks.values.toList();

  DownloadTask? getTask(String songId) => _tasks[songId];

  Future<void> startDownload(Song song) async {
    if (_tasks.containsKey(song.id)) {
      final task = _tasks[song.id]!;
      if (task.status == DownloadStatus.completed) return;
      if (task.status == DownloadStatus.paused) {
        resumeDownload(song.id);
        return;
      }
    }

    debugPrint(' [Download Manager] Queued download for: ${song.title}');
    _updateTask(DownloadTask(
      songId: song.id,
      title: song.title,
      artist: song.artist,
      status: DownloadStatus.queued,
      progress: 0.0,
    ));

    // Simulate small queue delay
    await Future.delayed(const Duration(milliseconds: 600));

    final currentTask = _tasks[song.id];
    if (currentTask == null || currentTask.status == DownloadStatus.cancelled) return;

    _runDownloadSimulation(song.id);
  }

  void pauseDownload(String songId) {
    final task = _tasks[songId];
    if (task == null || task.status != DownloadStatus.downloading) return;

    _timers[songId]?.cancel();
    _timers[songId] = null;

    debugPrint(' [Download Manager] Paused download for: ${task.title}');
    _updateTask(task.copyWith(status: DownloadStatus.paused));
  }

  void resumeDownload(String songId) {
    final task = _tasks[songId];
    if (task == null || task.status != DownloadStatus.paused) return;

    debugPrint(' [Download Manager] Resumed download for: ${task.title}');
    _runDownloadSimulation(songId);
  }

  void cancelDownload(String songId) {
    final task = _tasks[songId];
    if (task == null) return;

    _timers[songId]?.cancel();
    _timers[songId] = null;

    debugPrint(' [Download Manager] Cancelled download for: ${task.title}');
    _updateTask(task.copyWith(status: DownloadStatus.cancelled, progress: 0.0));
  }

  void _runDownloadSimulation(String songId) {
    final task = _tasks[songId];
    if (task == null) return;

    _updateTask(task.copyWith(status: DownloadStatus.downloading));

    double currentProgress = task.progress;
    _timers[songId] = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      final t = _tasks[songId];
      if (t == null || t.status != DownloadStatus.downloading) {
        timer.cancel();
        return;
      }

      currentProgress += 0.15;
      if (currentProgress >= 1.0) {
        timer.cancel();
        _timers[songId] = null;

        // Check for simulated download errors (e.g. title contains error/fail)
        if (t.title.toLowerCase().contains('error') || t.title.toLowerCase().contains('fail')) {
          debugPrint(' [Download Manager] Download FAILED for: ${t.title}');
          _updateTask(t.copyWith(
            status: DownloadStatus.failed,
            error: 'Storage write failed: Corrupt stream packet or Storage full.',
          ));
        } else {
          debugPrint(' [Download Manager] Download COMPLETED for: ${t.title}');
          _updateTask(t.copyWith(
            status: DownloadStatus.completed,
            progress: 1.0,
            localFilePath: 'C:/Users/vikrantrajput/.gemini/antigravity/scratch/da_music/downloads/${t.songId}.mp3',
          ));
        }
      } else {
        _updateTask(t.copyWith(progress: currentProgress.clamp(0.0, 1.0)));
      }
    });
  }

  void _updateTask(DownloadTask task) {
    _tasks[task.songId] = task;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer?.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}
