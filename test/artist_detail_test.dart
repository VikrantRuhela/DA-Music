import 'package:flutter_test/flutter_test.dart';
import 'package:da_music/core/services/youtube_music_adapter.dart';

void main() {
  group('YouTubeMusicAdapter Artist Detail Parsing Tests', () {
    late YouTubeMusicAdapter adapter;

    setUp(() async {
      adapter = YouTubeMusicAdapter();
      await adapter.initialize();
    });

    test('getArtist parses Imagine Dragons channel and sections correctly', () async {
      // Imagine Dragons channel ID
      const artistId = 'UCT9zcQNlyht7fRlcjmflRSA';
      final artist = await adapter.getArtist(artistId);

      // Verify artist basic metadata
      expect(artist.id, artistId);
      expect(artist.name, 'Imagine Dragons');
      expect(artist.image.url, startsWith('https://'));
      expect(artist.subscriberCount, greaterThan(10000000)); // Should be > 10M (Imagine Dragons is ~33.3M)

      // Verify cached shelves
      final topSongs = adapter.getArtistSongs(artistId);
      expect(topSongs, isNotEmpty);
      expect(topSongs.first.title, isNotEmpty);
      expect(topSongs.first.id, isNotEmpty);
      expect(topSongs.first.artwork.url, startsWith('https://'));

      final albums = adapter.getArtistAlbums(artistId);
      expect(albums, isNotEmpty);
      expect(albums.first.title, isNotEmpty);
      expect(albums.first.id, isNotEmpty);

      final singles = adapter.getArtistSingles(artistId);
      expect(singles, isNotEmpty);
      expect(singles.first.title, isNotEmpty);

      final related = adapter.getArtistRelated(artistId);
      expect(related, isNotEmpty);
      expect(related.first.name, isNotEmpty);
      expect(related.first.id, startsWith('UC'));
    });
  });
}
