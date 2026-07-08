import 'song.dart';
import 'album.dart';
import 'artist.dart';
import 'playlist.dart';

/// Immutable domain entity representing aggregated query search results.
class SearchResult {
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Playlist> playlists;
  final dynamic topResult;

  const SearchResult({
    required this.songs,
    required this.albums,
    required this.artists,
    required this.playlists,
    this.topResult,
  });

  SearchResult copyWith({
    List<Song>? songs,
    List<Album>? albums,
    List<Artist>? artists,
    List<Playlist>? playlists,
    dynamic topResult,
  }) {
    return SearchResult(
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      playlists: playlists ?? this.playlists,
      topResult: topResult ?? this.topResult,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          topResult == other.topResult &&
          _listEquals(songs, other.songs) &&
          _listEquals(albums, other.albums) &&
          _listEquals(artists, other.artists) &&
          _listEquals(playlists, other.playlists);

  @override
  int get hashCode =>
      topResult.hashCode ^
      songs.fold(0, (prev, element) => prev ^ element.hashCode) ^
      albums.fold(0, (prev, element) => prev ^ element.hashCode) ^
      artists.fold(0, (prev, element) => prev ^ element.hashCode) ^
      playlists.fold(0, (prev, element) => prev ^ element.hashCode);

  bool _listEquals(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'SearchResult{songsCount: ${songs.length}, albumsCount: ${albums.length}, artistsCount: ${artists.length}, playlistsCount: ${playlists.length}, topResult: $topResult}';
  }
}
