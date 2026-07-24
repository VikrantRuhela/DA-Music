import '../../domain/entities/song.dart';
import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/audio_stream.dart';

/// Abstract MusicSourceAdapter interface for pluggable music source adapters.
abstract class MusicSourceAdapter {
  String get id;
  String get name;

  Future<void> initialize();
  Future<void> dispose();

  Future<SearchResult> search(String query);
  Future<List<Artist>> searchArtists(String query) async {
    final res = await search(query);
    return res.artists;
  }
  Future<HomeFeed> getHome();
  Future<Album> getAlbum(String id);
  Future<Artist> getArtist(String id);
  Future<Playlist> getPlaylist(String id);
  Future<Song> getSong(String id);
  Future<Lyrics> getLyrics(String id);
  Future<List<Song>> getRelated(String id);
  Future<List<Song>> getRecommendations(String id);
  Future<AudioStream> getAudioStream(String id);

  List<Song> getArtistSongs(String artistId) => const [];
  List<Album> getArtistAlbums(String artistId) => const [];
  List<Album> getArtistSingles(String artistId) => const [];
  List<Playlist> getArtistPlaylists(String artistId) => const [];
  List<Artist> getArtistRelated(String artistId) => const [];
}
