import '../entities/song.dart';

abstract class SongRepository {
  Future<Song> getSongById(String id);
  Future<List<Song>> getSongsByQuery(String query);
  Future<List<Song>> getRelatedSongs(String songId);
}
