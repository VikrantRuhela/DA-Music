import '../../domain/entities/song.dart';
import '../../domain/entities/playlist.dart';

abstract class LibraryService {
  Future<List<Song>> getLikedSongs();
  Future<void> likeSong(Song song);
  Future<void> unlikeSong(String id);
  Future<List<Playlist>> getPlaylists();
}
