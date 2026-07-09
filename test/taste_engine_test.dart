import 'package:flutter_test/flutter_test.dart';
import 'package:da_music/features/taste_engine/domain/taste_analyzer.dart';
import 'package:da_music/features/taste_engine/domain/music_dna.dart';

void main() {
  group('Intelligent Taste Engine - TasteAnalyzer Tests', () {
    test('Empty logs should return default MusicDNA', () {
      final dna = TasteAnalyzer.analyze([], downloadCount: 5, favoriteCount: 10);
      expect(dna.downloadCount, 5);
      expect(dna.favoriteCount, 10);
      expect(dna.topArtists, isEmpty);
      expect(dna.listeningMood, 'Neutral');
    });

    test('Analyze completed plays vs skipped plays', () {
      final logs = [
        // Completed play (100%)
        {
          'songId': 'song1',
          'songTitle': 'Song One',
          'artist': 'Artist A',
          'album': 'Album X',
          'genre': 'Rock',
          'completionPercentage': 100.0,
          'completed': true,
          'durationMs': 180000,
          'sessionId': 'session_1',
          'startTime': '2026-07-09T08:00:00Z',
        },
        // Completed play (90%)
        {
          'songId': 'song1',
          'songTitle': 'Song One',
          'artist': 'Artist A',
          'album': 'Album X',
          'genre': 'Rock',
          'completionPercentage': 90.0,
          'completed': true,
          'durationMs': 180000,
          'sessionId': 'session_1',
          'startTime': '2026-07-09T08:05:00Z',
        },
        // Skipped play (10%)
        {
          'songId': 'song2',
          'songTitle': 'Song Two',
          'artist': 'Artist B',
          'album': 'Album Y',
          'genre': 'Pop',
          'completionPercentage': 10.0,
          'completed': false,
          'durationMs': 200000,
          'sessionId': 'session_1',
          'startTime': '2026-07-09T08:10:00Z',
        },
      ];

      final dna = TasteAnalyzer.analyze(logs, downloadCount: 1, favoriteCount: 2);

      expect(dna.downloadCount, 1);
      expect(dna.favoriteCount, 2);
      expect(dna.completionRate, closeTo(2.0 / 3.0, 0.01));
      expect(dna.skipRate, closeTo(1.0 / 3.0, 0.01));
      expect(dna.topArtists, contains('Artist A'));
      expect(dna.topSongs, contains('Song One'));
      expect(dna.favoriteGenres, contains('Rock'));
      expect(dna.peakListeningTime, contains('Morning'));
    });

    test('Analyze replay rate and mood classification', () {
      final logs = [
        {
          'songId': 'song1',
          'songTitle': 'Song One',
          'artist': 'Artist A',
          'completionPercentage': 100.0,
          'completed': true,
          'sessionId': 'session_2',
          'startTime': '2026-07-09T23:00:00Z',
        },
        {
          'songId': 'song1',
          'songTitle': 'Song One',
          'artist': 'Artist A',
          'completionPercentage': 100.0,
          'completed': true,
          'sessionId': 'session_2',
          'startTime': '2026-07-09T23:05:00Z',
        },
      ];

      final dna = TasteAnalyzer.analyze(logs);

      // 2 plays, 1 unique song -> replay rate should be (2 - 1) / 2 = 50%
      expect(dna.replayRate, 0.5);
      expect(dna.listeningMood, 'Chill & Relaxed');
    });
  });
}
