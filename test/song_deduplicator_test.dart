import 'package:flutter_test/flutter_test.dart';
import 'package:da_tunes/core/services/song_deduplicator.dart';
import 'package:da_tunes/domain/entities/song.dart';
import 'package:da_tunes/domain/entities/value_objects.dart';

void main() {
  group('SongDeduplicator Tests', () {
    test('Normalizes song titles correctly', () {
      expect(SongDeduplicator.normalizeTitle('Sohniye (Official Video)'), 'sohniye');
      expect(SongDeduplicator.normalizeTitle('Sohniye - Official Audio'), 'sohniye');
      expect(SongDeduplicator.normalizeTitle('Sohniye [Lyric Video] HD 4K'), 'sohniye');
    });

    test('Preserves legitimate alternate versions', () {
      expect(SongDeduplicator.normalizeTitle('Sohniye (Remix)'), 'sohniye remix');
      expect(SongDeduplicator.normalizeTitle('Sohniye (Live at Stadium)'), 'sohniye live at stadium');
      expect(SongDeduplicator.normalizeTitle('Sohniye (Acoustic Version)'), 'sohniye acoustic version');
    });

    test('Deduplicates duplicate uploads and prefers Official Audio', () {
      final song1 = Song(
        id: '1',
        title: 'Sohniye (Official Video)',
        artistId: 'Artist',
        albumId: 'Album',
        duration: DurationValue(const Duration(minutes: 3, seconds: 30)),
        thumbnail: Artwork('url1'),
        artwork: Artwork('url1'),
        sourceId: 'youtube_music',
      );

      final song2 = Song(
        id: '2',
        title: 'Sohniye (Official Audio)',
        artistId: 'Artist',
        albumId: 'Album',
        duration: DurationValue(const Duration(minutes: 3, seconds: 30)),
        thumbnail: Artwork('url2'),
        artwork: Artwork('url2'),
        sourceId: 'youtube_music',
      );

      final song3 = Song(
        id: '3',
        title: 'Sohniye (Remix)',
        artistId: 'Artist',
        albumId: 'Album',
        duration: DurationValue(const Duration(minutes: 3, seconds: 30)),
        thumbnail: Artwork('url3'),
        artwork: Artwork('url3'),
        sourceId: 'youtube_music',
      );

      final result = SongDeduplicator.deduplicate([song1, song2, song3]);
      expect(result.length, 2);
      expect(result.any((s) => s.id == '2'), true);
      expect(result.any((s) => s.id == '3'), true);
    });
  });
}
