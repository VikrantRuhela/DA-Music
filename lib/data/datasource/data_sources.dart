import '../models/data_models.dart';

/// Abstract Remote Music Data Source contract.
abstract class RemoteMusicDataSource {
  Future<SongModel> getSongById(String id);
  Future<List<SongModel>> getSongsByQuery(String query);
  Future<AlbumModel> getAlbumById(String id);
  Future<List<AlbumModel>> getAlbumsByQuery(String query);
  Future<ArtistModel> getArtistById(String id);
  Future<List<ArtistModel>> getArtistsByQuery(String query);
  Future<PlaylistModel> getPlaylistById(String id);
  Future<List<PlaylistModel>> getPlaylistsByQuery(String query);
  Future<SearchResultModel> search(String query);
  Future<List<SongModel>> getRecommendations(String songId);
}

/// Abstract Local Music Data Source contract.
abstract class LocalMusicDataSource {
  Future<List<SongModel>> getLikedSongs();
  Future<void> saveLikedSong(SongModel song);
  Future<void> removeLikedSong(String id);
  Future<List<PlaylistModel>> getPlaylists();
  Future<void> savePlaylist(PlaylistModel playlist);
  Future<void> deletePlaylist(String id);
}

/// Abstract Cache Data Source contract.
abstract class CacheDataSource {
  Future<String?> get(String key);
  Future<void> put(String key, String value);
  Future<void> remove(String key);
  Future<void> clear();
}

/// Abstract Artwork Data Source contract.
abstract class ArtworkDataSource {
  Future<String?> getArtworkUrl(String query);
}



/// Abstract Lyrics Data Source contract.
abstract class LyricsDataSource {
  Future<LyricsModel> getLyrics(String songId);
  Future<void> saveLyrics(LyricsModel lyrics);
}

/// Abstract History Data Source contract.
abstract class HistoryDataSource {
  Future<List<SongModel>> getRecentlyPlayed();
  Future<void> addSongToHistory(SongModel song);
}

/// Abstract Settings Data Source contract.
abstract class SettingsDataSource {
  Future<SettingsModel> loadSettings();
  Future<void> saveSettings(SettingsModel settings);
}
