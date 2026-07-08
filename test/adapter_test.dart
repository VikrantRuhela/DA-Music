import 'package:flutter_test/flutter_test.dart';
import 'package:da_music/core/services/youtube_music_adapter.dart';

void main() {
  group('YouTubeMusicAdapter Detail Parsing Tests', () {
    late YouTubeMusicAdapter adapter;

    setUp(() async {
      adapter = YouTubeMusicAdapter();
      await adapter.initialize();
    });

    test('getPlaylist retrieves track list and high-res artwork', () async {
      const playlistId = 'RDCLAK5uy_m9Rw_g5eCJtMhuRgP1eqU3H-XW7UL6uWQ';
      final playlist = await adapter.getPlaylist(playlistId);
      
      expect(playlist.id, playlistId);
      expect(playlist.title, 'Indie Anthems');
      expect(playlist.owner, isNotEmpty);
      expect(playlist.cover.url, startsWith('https://'));
      expect(playlist.songIds, isNotEmpty);
      expect(playlist.songIds.length, greaterThan(50));
    });

    test('getAlbum retrieves track count and cover artwork', () async {
      const albumId = 'RDCLAK5uy_m9Rw_g5eCJtMhuRgP1eqU3H-XW7UL6uWQ';
      final album = await adapter.getAlbum(albumId);
      
      expect(album.id, albumId);
      expect(album.title, 'Indie Anthems');
      expect(album.artistId, isNotEmpty);
      expect(album.cover.url, startsWith('https://'));
      expect(album.trackCount, greaterThan(50));
    });
  });
}
