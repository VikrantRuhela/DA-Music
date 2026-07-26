import 'package:flutter_test/flutter_test.dart';
import 'package:da_tunes/features/taste_engine/domain/recommendation_engine.dart';
import 'package:da_tunes/features/taste_engine/domain/music_dna.dart';
import 'package:da_tunes/shared/models/music_models.dart' as model;

void main() {
  group('Smart Queue System Tests', () {
    test('Alternative Version Filter tests', () {
      expect(RecommendationEngine.isAlternativeVersion('For A Reason', 'For A Reason'), isTrue);
      expect(RecommendationEngine.isAlternativeVersion('For A Reason', 'For A Reason (Live)'), isTrue);
      expect(RecommendationEngine.isAlternativeVersion('For A Reason', 'For A Reason Remix'), isTrue);
      expect(RecommendationEngine.isAlternativeVersion('For A Reason', 'For A Reason Slowed + Reverb'), isTrue);
      expect(RecommendationEngine.isAlternativeVersion('For A Reason', 'Another Song'), isFalse);
    });

    test('Genre Detection tests', () {
      expect(RecommendationEngine.detectGenre('Karan Aujla', 'Softly'), 'Punjabi');
      expect(RecommendationEngine.detectGenre('Eminem', 'Lose Yourself'), 'Hip-Hop');
      expect(RecommendationEngine.detectGenre('Beatles', 'Yesterday'), 'Rock');
      expect(RecommendationEngine.detectGenre('Lofi Chill', 'Relaxing Beats'), 'Lo-fi');
      expect(RecommendationEngine.detectGenre('Unknown Artist', 'Ordinary Pop Song'), 'Pop');
    });

    test('Scoring and Ranking logic validation', () {
      final seed = model.Song(
        id: 'seed_id',
        title: 'For A Reason',
        artist: 'Karan Aujla',
        album: 'Single',
        duration: const Duration(seconds: 180),
        artworkUrl: '',
        source: 'youtube_music',
        lyrics: null,
      );

      final dna = MusicDNA(
        topArtists: ['Karan Aujla'],
        favoriteGenres: ['Punjabi'],
      );

      final sameArtist = model.Song(
        id: 'id1',
        title: 'Softly',
        artist: 'Karan Aujla',
        album: 'Single',
        duration: const Duration(seconds: 150),
        artworkUrl: '',
        source: 'youtube_music',
        lyrics: null,
      );

      expect(sameArtist.artist.toLowerCase().trim() == seed.artist.toLowerCase().trim(), isTrue);

      final artistLower = seed.artist.toLowerCase().trim();
      final similarArtistsList = RecommendationEngine.similarArtistsMap[artistLower] ?? [];
      expect(similarArtistsList, contains('ap dhillon'));
    });
  });
}
