import 'dart:math';
import '../../shared/models/music_models.dart';
import '../exceptions/playback_exceptions.dart';

class QueueManager {
  final List<QueueItem> _originalQueue = [];
  final List<QueueItem> _activeQueue = [];
  int _currentIndex = -1;
  bool _isShuffle = false;

  List<QueueItem> get queue => List.unmodifiable(_activeQueue);
  int get currentIndex => _currentIndex;

  Song? get currentSong {
    if (_currentIndex >= 0 && _currentIndex < _activeQueue.length) {
      return _activeQueue[_currentIndex].song;
    }
    return null;
  }

  bool get hasNext => _currentIndex < _activeQueue.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  void setQueue(List<Song> songs, {int startIndex = 0}) {
    _originalQueue.clear();
    for (int i = 0; i < songs.length; i++) {
      _originalQueue.add(QueueItem(id: 'q_${DateTime.now().microsecondsSinceEpoch}_$i', song: songs[i]));
    }
    _activeQueue.clear();
    _activeQueue.addAll(_originalQueue);

    if (_isShuffle) {
      _shuffleInternal(keepCurrent: false);
      _currentIndex = 0;
    } else {
      if (startIndex >= 0 && startIndex < _activeQueue.length) {
        _currentIndex = startIndex;
      } else {
        _currentIndex = 0;
      }
    }
  }

  void insertNext(Song song) {
    final item = QueueItem(id: 'q_${DateTime.now().microsecondsSinceEpoch}', song: song);
    if (_activeQueue.isEmpty) {
      _activeQueue.add(item);
      _currentIndex = 0;
    } else {
      _activeQueue.insert(_currentIndex + 1, item);
    }
    _originalQueue.add(item);
  }

  void remove(String queueItemId) {
    final index = _activeQueue.indexWhere((item) => item.id == queueItemId);
    if (index == -1) throw const QueueException('Item not found in queue');

    if (index == _currentIndex) {
      if (hasNext) {
        // stay on same index (next song moves into current spot)
      } else if (hasPrevious) {
        _currentIndex--;
      } else {
        _currentIndex = -1;
      }
    } else if (index < _currentIndex) {
      _currentIndex--;
    }

    _activeQueue.removeAt(index);
    _originalQueue.removeWhere((item) => item.id == queueItemId);
  }

  void move(int from, int to) {
    if (from < 0 || from >= _activeQueue.length || to < 0 || to >= _activeQueue.length) {
      throw const QueueException('Invalid queue positions');
    }

    final item = _activeQueue.removeAt(from);
    _activeQueue.insert(to, item);

    if (_currentIndex == from) {
      _currentIndex = to;
    } else if (from < _currentIndex && to >= _currentIndex) {
      _currentIndex--;
    } else if (from > _currentIndex && to <= _currentIndex) {
      _currentIndex++;
    }
  }

  void setShuffle(bool shuffle) {
    if (_isShuffle == shuffle) return;
    _isShuffle = shuffle;

    if (_isShuffle) {
      _shuffleInternal(keepCurrent: true);
    } else {
      final currentItem = _currentIndex >= 0 && _currentIndex < _activeQueue.length ? _activeQueue[_currentIndex] : null;
      _activeQueue.clear();
      _activeQueue.addAll(_originalQueue);
      if (currentItem != null) {
        _currentIndex = _activeQueue.indexWhere((item) => item.id == currentItem.id);
      }
    }
  }

  void _shuffleInternal({required bool keepCurrent}) {
    if (_activeQueue.isEmpty) return;

    final currentItem = keepCurrent && _currentIndex >= 0 && _currentIndex < _activeQueue.length ? _activeQueue[_currentIndex] : null;
    final listToShuffle = List<QueueItem>.from(_activeQueue);

    if (currentItem != null) {
      listToShuffle.removeAt(_currentIndex);
    }

    listToShuffle.shuffle(Random());

    _activeQueue.clear();
    if (currentItem != null) {
      _activeQueue.add(currentItem);
      _currentIndex = 0;
    }
    _activeQueue.addAll(listToShuffle);
  }

  Song? next() {
    if (!hasNext) return null;
    _currentIndex++;
    return currentSong;
  }

  Song? previous() {
    if (!hasPrevious) return null;
    _currentIndex--;
    return currentSong;
  }

  void clear() {
    _originalQueue.clear();
    _activeQueue.clear();
    _currentIndex = -1;
  }
}
