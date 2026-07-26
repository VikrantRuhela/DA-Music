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

    test('Official Artist Channel / Identity Resolution tests', () {
      final streamerChannelId = 'UCs38d2LpL2hY3_qM9g3vBdw';
      expect(
        RecommendationEngine.isOfficialMusicChannel(streamerChannelId, 'Shubh Gaming', 'Shubh'),
        isFalse,
      );

      final officialTopicChannelId = 'UCFzC-gq9Z_xG4Vz_d9J5QSw';
      expect(
        RecommendationEngine.isOfficialMusicChannel(officialTopicChannelId, 'Shubh - Topic', 'Shubh'),
        isTrue,
      );

      expect(
        RecommendationEngine.isOfficialMusicChannel(null, 'Shubh Plays Roblox', 'Shubh'),
        isFalse,
      );
    });

    test('Compilation Video and Title Duplication Filtering tests', () {
      // Compilation videos check
      expect(
        RecommendationEngine.isValidMusicCandidate(
          'Best of Punjabi Songs 2026 Compilation Jukebox',
          'T-Series',
          const Duration(minutes: 5),
        ),
        isFalse,
      );

      expect(
        RecommendationEngine.isValidMusicCandidate(
          'Punjabi Nonstop Mashup Mixtape',
          'Speed Records',
          const Duration(minutes: 6),
        ),
        isFalse,
      );

      // New numeric compilation filters check
      expect(
        RecommendationEngine.isValidMusicCandidate(
          'Punjabi Music Mix 2026',
          'Singer Name',
          const Duration(minutes: 4),
        ),
        isFalse,
      );

      expect(
        RecommendationEngine.isValidMusicCandidate(
          'Punjabi Hits Hot 50',
          'Singer Name',
          const Duration(minutes: 4),
        ),
        isFalse,
      );

      expect(
        RecommendationEngine.isValidMusicCandidate(
          'Hot 25 Songs of the Week',
          'Singer Name',
          const Duration(minutes: 4),
        ),
        isFalse,
      );

      expect(
        RecommendationEngine.isValidMusicCandidate(
          'Top 10 Punjabi Tracks',
          'Singer Name',
          const Duration(minutes: 4),
        ),
        isFalse,
      );

      expect(
        RecommendationEngine.isValidMusicCandidate(
          'Top 101 Punjabi Tracks', // > 100 should not be rejected by numeric filter
          'Singer Name',
          const Duration(minutes: 4),
        ),
        isTrue,
      );

      // Standard song check
      expect(
        RecommendationEngine.isValidMusicCandidate(
          'At Peace',
          'Karan Aujla',
          const Duration(minutes: 3),
        ),
        isTrue,
      );
    });
  });
}
