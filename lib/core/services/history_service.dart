import '../../domain/entities/song.dart';

abstract class HistoryService {
  Future<List<Song>> getRecentlyPlayed();
  Future<void> recordPlay(Song song);
}
