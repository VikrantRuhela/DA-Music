import 'song.dart';
import 'repeat_mode.dart';

/// Immutable domain entity representing a queue of songs and active play parameters.
class Queue {
  final List<Song> songs;
  final int currentIndex;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;

  Queue({
    required this.songs,
    required this.currentIndex,
    required this.repeatMode,
    required this.shuffleEnabled,
  }) {
    if (currentIndex < -1) {
      throw ArgumentError('CurrentIndex cannot be less than -1.');
    }
    if (currentIndex != -1 && songs.length <= currentIndex) {
      throw ArgumentError('CurrentIndex cannot exceed total queue track count.');
    }
  }

  Song? currentSong() {
    if (currentIndex >= 0 && currentIndex < songs.length) {
      return songs[currentIndex];
    }
    return null;
  }

  Queue next() {
    if (songs.isEmpty) return this;

    if (repeatMode == RepeatMode.one) {
      return this;
    }

    int nextIndex = currentIndex + 1;
    if (nextIndex >= songs.length) {
      nextIndex = (repeatMode == RepeatMode.all) ? 0 : songs.length - 1;
    }

    return copyWith(currentIndex: nextIndex);
  }

  Queue previous() {
    if (songs.isEmpty) return this;

    if (repeatMode == RepeatMode.one) {
      return this;
    }

    int prevIndex = currentIndex - 1;
    if (prevIndex < 0) {
      prevIndex = (repeatMode == RepeatMode.all) ? songs.length - 1 : 0;
    }

    return copyWith(currentIndex: prevIndex);
  }

  Queue move(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= songs.length) return this;
    if (newIndex < 0 || newIndex >= songs.length) return this;

    final updatedSongs = List<Song>.from(songs);
    final Song song = updatedSongs.removeAt(oldIndex);
    updatedSongs.insert(newIndex, song);

    // Adjust currentIndex accordingly
    int nextCurrentIndex = currentIndex;
    if (currentIndex == oldIndex) {
      nextCurrentIndex = newIndex;
    } else if (currentIndex > oldIndex && currentIndex <= newIndex) {
      nextCurrentIndex--;
    } else if (currentIndex < oldIndex && currentIndex >= newIndex) {
      nextCurrentIndex++;
    }

    return copyWith(songs: updatedSongs, currentIndex: nextCurrentIndex);
  }

  Queue insert(Song song) {
    final updatedSongs = List<Song>.from(songs);
    updatedSongs.add(song);

    int nextCurrentIndex = currentIndex;
    if (currentIndex == -1) {
      nextCurrentIndex = 0;
    }

    return copyWith(songs: updatedSongs, currentIndex: nextCurrentIndex);
  }

  Queue remove(int index) {
    if (index < 0 || index >= songs.length) return this;

    final updatedSongs = List<Song>.from(songs);
    updatedSongs.removeAt(index);

    int nextCurrentIndex = currentIndex;
    if (updatedSongs.isEmpty) {
      nextCurrentIndex = -1;
    } else if (currentIndex == index) {
      nextCurrentIndex = index < updatedSongs.length ? index : updatedSongs.length - 1;
    } else if (currentIndex > index) {
      nextCurrentIndex--;
    }

    return copyWith(songs: updatedSongs, currentIndex: nextCurrentIndex);
  }

  Queue clear() {
    return copyWith(songs: [], currentIndex: -1);
  }

  Queue copyWith({
    List<Song>? songs,
    int? currentIndex,
    RepeatMode? repeatMode,
    bool? shuffleEnabled,
  }) {
    return Queue(
      songs: songs ?? this.songs,
      currentIndex: currentIndex ?? this.currentIndex,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Queue &&
          runtimeType == other.runtimeType &&
          currentIndex == other.currentIndex &&
          repeatMode == other.repeatMode &&
          shuffleEnabled == other.shuffleEnabled &&
          _listEquals(songs, other.songs);

  @override
  int get hashCode =>
      currentIndex.hashCode ^
      repeatMode.hashCode ^
      shuffleEnabled.hashCode ^
      songs.fold(0, (prev, element) => prev ^ element.hashCode);

  bool _listEquals(List<Song> a, List<Song> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'Queue{songsCount: ${songs.length}, currentIndex: $currentIndex, repeat: $repeatMode, shuffle: $shuffleEnabled}';
  }
}
