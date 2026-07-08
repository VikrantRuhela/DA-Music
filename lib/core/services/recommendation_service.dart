import '../../domain/entities/song.dart';

abstract class RecommendationService {
  Future<List<Song>> getRecommendations(String songId);
}
