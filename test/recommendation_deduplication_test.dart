// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'package:flutter_test/flutter_test.dart';
import 'package:da_tunes/features/taste_engine/presentation/providers/taste_engine_providers.dart';
import 'package:da_tunes/domain/entities/song.dart';
import 'package:da_tunes/domain/entities/value_objects.dart';

void main() {
  group('Home Recommendation Deduplication Tests', () {
    test('getSongDeduplicationKey normalizes title and recognizes identical songs', () {
      final key1 = getSongDeduplicationKey('v123', 'Blinding Lights (Official Video)', 'The Weeknd');
      final key2 = getSongDeduplicationKey('v456', 'Blinding Lights [Official Audio]', 'The Weeknd');
      final key3 = getSongDeduplicationKey('v123', 'Blinding Lights', 'The Weeknd');

      // Both key1 and key3 use ID v123
      expect(key1, contains('v123'));
      expect(key3, contains('v123'));

      // Clean title normalization handles (Official Video) vs [Official Audio]
      final meta1 = getSongDeduplicationKey('', 'Blinding Lights (Official Video)', 'The Weeknd');
      final meta2 = getSongDeduplicationKey('', 'Blinding Lights [Official Audio]', 'The Weeknd');
      expect(meta1, equals(meta2));
      expect(meta1, equals('meta:blinding lights|the weeknd'));
    });

    test('Cross-section deduplication replaces duplicate songs without shortening sections', () {
      final Set<String> globalSeenSongKeys = {};

      final sourcePoolSection1 = [
        Song(id: 's1', title: 'Song 1', artistId: 'Artist A', albumId: 'Album X', duration: DurationValue(const Duration(minutes: 3)), thumbnail: Artwork(''), artwork: Artwork(''), sourceId: 'youtube'),
        Song(id: 's2', title: 'Song 2', artistId: 'Artist B', albumId: 'Album Y', duration: DurationValue(const Duration(minutes: 3)), thumbnail: Artwork(''), artwork: Artwork(''), sourceId: 'youtube'),
        Song(id: 's3', title: 'Song 3', artistId: 'Artist C', albumId: 'Album Z', duration: DurationValue(const Duration(minutes: 3)), thumbnail: Artwork(''), artwork: Artwork(''), sourceId: 'youtube'),
      ];

      // Populate Section 1 ("Recently Played")
      final section1Items = <Song>[];
      for (final song in sourcePoolSection1) {
        final key = getSongDeduplicationKey(song.id, song.title, song.artistId, song.albumId);
        if (!globalSeenSongKeys.contains(key)) {
          globalSeenSongKeys.add(key);
          section1Items.add(song);
        }
      }
      expect(section1Items.length, equals(3));

      // Source Pool for Section 2 ("Trending"): Contains 'Song 1' (duplicate from Section 1) and replacement candidate 'Song 4'
      final sourcePoolSection2 = [
        Song(id: 's1', title: 'Song 1', artistId: 'Artist A', albumId: 'Album X', duration: DurationValue(const Duration(minutes: 3)), thumbnail: Artwork(''), artwork: Artwork(''), sourceId: 'youtube'),
        Song(id: 's4', title: 'Song 4', artistId: 'Artist D', albumId: 'Album W', duration: DurationValue(const Duration(minutes: 3)), thumbnail: Artwork(''), artwork: Artwork(''), sourceId: 'youtube'),
        Song(id: 's5', title: 'Song 5', artistId: 'Artist E', albumId: 'Album V', duration: DurationValue(const Duration(minutes: 3)), thumbnail: Artwork(''), artwork: Artwork(''), sourceId: 'youtube'),
      ];

      final section2Items = <Song>[];
      for (final song in sourcePoolSection2) {
        final key = getSongDeduplicationKey(song.id, song.title, song.artistId, song.albumId);
        if (!globalSeenSongKeys.contains(key)) {
          globalSeenSongKeys.add(key);
          section2Items.add(song);
        }
      }

      // 'Song 1' must be skipped because it appeared in Section 1, and replaced by 'Song 4' & 'Song 5'
      expect(section2Items.any((s) => s.id == 's1'), isFalse);
      expect(section2Items.map((s) => s.id), equals(['s4', 's5']));
      expect(section2Items.length, equals(2));

      // Verify no duplicates exist across all items across all sections
      final allItems = [...section1Items, ...section2Items];
      final allKeys = allItems.map((s) => getSongDeduplicationKey(s.id, s.title, s.artistId, s.albumId)).toList();
      expect(allKeys.length, equals(allKeys.toSet().length));
    });
  });
}
