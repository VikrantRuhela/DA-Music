import '../entities/artist.dart';

abstract class ArtistRepository {
  Future<Artist> getArtistById(String id);
  Future<List<Artist>> getArtistsByQuery(String query);
}
