import '../entities/song.dart';

abstract class HistoryRepository {
  Future<List<Song>> getRecentlyPlayed();
  Future<void> addSongToHistory(Song song);
}
