import '../entities/album.dart';

abstract class AlbumRepository {
  Future<Album> getAlbumById(String id);
  Future<List<Album>> getAlbumsByQuery(String query);
}
