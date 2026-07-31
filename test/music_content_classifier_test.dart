// SPDX-License-Identifier: GPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import '../lib/core/services/music_content_classifier.dart';
import '../lib/domain/entities/song.dart';
import '../lib/domain/entities/value_objects.dart';

void main() {
  group('MusicContentClassifier Tests', () {
    test('Identifies blacklisted keywords in title or channel', () {
      expect(MusicContentClassifier.isBlacklistedTitleOrChannel('Minecraft Gameplay Episode 1', 'GamerChannel'), true);
      expect(MusicContentClassifier.isBlacklistedTitleOrChannel('Podcast #42: Tech Review', 'TalkShow'), true);
      expect(MusicContentClassifier.isBlacklistedTitleOrChannel('Blinding Lights', 'The Weeknd'), false);
    });

    test('Computes confidence scores correctly', () {
      final songScore = MusicContentClassifier.calculateConfidenceScore(
        title: 'Starboy',
        artist: 'The Weeknd - Topic',
        duration: const Duration(minutes: 3, seconds: 50),
        isTopicChannel: true,
        fromMusicShelf: true,
        hasMusicPageType: true,
      );
      expect(songScore, greaterThanOrEqualTo(80));

      final nonMusicScore = MusicContentClassifier.calculateConfidenceScore(
        title: 'GTA 5 Walkthrough Gameplay',
        artist: 'GamingCentral',
        duration: const Duration(minutes: 45),
      );
      expect(nonMusicScore, lessThan(40));
    });

    test('Validates song entities', () {
      final validSong = Song(
        id: 's1',
        title: 'Shape of You',
        artistId: 'Ed Sheeran',
        albumId: 'Divide',
        duration: DurationValue(const Duration(minutes: 3, seconds: 53)),
        thumbnail: Artwork(''),
        artwork: Artwork(''),
        sourceId: 'ytm',
      );
      expect(MusicContentClassifier.isMusicSong(validSong), true);

      final invalidSong = Song(
        id: 's2',
        title: 'Unboxing iPhone 16 Pro Review',
        artistId: 'TechReviewer',
        albumId: 'yt_album_unknown',
        duration: DurationValue(const Duration(minutes: 25)),
        thumbnail: Artwork(''),
        artwork: Artwork(''),
        sourceId: 'ytm',
      );
      expect(MusicContentClassifier.isMusicSong(invalidSong), false);
    });
  });
}
