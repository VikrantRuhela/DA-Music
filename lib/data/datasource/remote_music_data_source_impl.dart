import '../models/data_models.dart';
import 'data_sources.dart';
import '../../core/services/source_manager.dart';
import '../../core/services/youtube_music_adapter.dart';

/// Concrete Remote Music Data Source wrapping the Source Manager adapter routing system.
class RemoteMusicDataSourceImpl implements RemoteMusicDataSource {
  final SourceManager _sourceManager;

  RemoteMusicDataSourceImpl({SourceManager? sourceManager})
      : _sourceManager = sourceManager ?? SourceManager() {
    _sourceManager.registerAdapter(YouTubeMusicAdapter());
    _sourceManager.selectSource('youtube_music');
  }

  @override
  Future<SearchResultModel> search(String query) async {
    final domainResult = await _sourceManager.search(query);
    return SearchResultModel(
      songs: domainResult.songs.map((s) => SongModel.fromEntity(s)).toList(),
      albums: domainResult.albums.map((a) => AlbumModel.fromEntity(a)).toList(),
      artists: domainResult.artists.map((a) => ArtistModel.fromEntity(a)).toList(),
      playlists: domainResult.playlists.map((p) => PlaylistModel.fromEntity(p)).toList(),
      topResult: domainResult.topResult != null ? SongModel.fromEntity(domainResult.topResult!) : null,
    );
  }

  @override
  Future<SongModel> getSongById(String id) async {
    final song = await _sourceManager.getSong(id);
    return SongModel.fromEntity(song);
  }

  @override
  Future<List<SongModel>> getSongsByQuery(String query) async {
    final domainResult = await _sourceManager.search(query);
    return domainResult.songs.map((s) => SongModel.fromEntity(s)).toList();
  }

  @override
  Future<AlbumModel> getAlbumById(String id) async {
    final album = await _sourceManager.getAlbum(id);
    return AlbumModel.fromEntity(album);
  }

  @override
  Future<List<AlbumModel>> getAlbumsByQuery(String query) async {
    final domainResult = await _sourceManager.search(query);
    return domainResult.albums.map((a) => AlbumModel.fromEntity(a)).toList();
  }

  @override
  Future<ArtistModel> getArtistById(String id) async {
    final artist = await _sourceManager.getArtist(id);
    return ArtistModel.fromEntity(artist);
  }

  @override
  Future<List<ArtistModel>> getArtistsByQuery(String query) async {
    final domainArtists = await _sourceManager.searchArtists(query);
    return domainArtists.map((a) => ArtistModel.fromEntity(a)).toList();
  }

  @override
  Future<PlaylistModel> getPlaylistById(String id) async {
    final playlist = await _sourceManager.getPlaylist(id);
    return PlaylistModel.fromEntity(playlist);
  }

  @override
  Future<List<PlaylistModel>> getPlaylistsByQuery(String query) async {
    final domainResult = await _sourceManager.search(query);
    return domainResult.playlists.map((p) => PlaylistModel.fromEntity(p)).toList();
  }

  @override
  Future<List<SongModel>> getRecommendations(String songId) async {
    final songs = await _sourceManager.getRecommendations(songId);
    return songs.map((s) => SongModel.fromEntity(s)).toList();
  }
}
