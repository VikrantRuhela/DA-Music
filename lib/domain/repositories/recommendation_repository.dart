import '../entities/song.dart';

abstract class RecommendationRepository {
  Future<List<Song>> getRecommendations(String songId);
}
