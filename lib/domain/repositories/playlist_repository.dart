import '../entities/playlist.dart';

abstract class PlaylistRepository {
  Future<Playlist> getPlaylistById(String id);
  Future<List<Playlist>> getPlaylistsByQuery(String query);
  Future<void> createPlaylist(String name);
  Future<void> deletePlaylist(String id);
}
