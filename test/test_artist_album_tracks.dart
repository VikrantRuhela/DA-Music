import 'package:flutter_test/flutter_test.dart';
import 'package:da_music/core/services/youtube_music_adapter.dart';

void main() {
  test('Test artist album tracks loading', () async {
    print('--- Testing Artist Album Tracks Loading ---');
    final adapter = YouTubeMusicAdapter();
    await adapter.initialize();

    // Imagine Dragons Album: "Reflections (From The Vault Of Smoke + Mirrors)"
    const albumId = 'MPREb_WOqUMNyA4PV'; 
    print('Loading album metadata...');
    try {
      final album = await adapter.getAlbum(albumId);
      print('Album Title: ${album.title}');
      print('Album Artist: ${album.artistId}');
      print('Album Year: ${album.year}');
      print('Album Track Count: ${album.trackCount}');
      print('Album Cover: ${album.cover.url}');

      print('\nLoading album playlist...');
      final playlist = await adapter.getPlaylist(albumId);
      print('Playlist Track ID Count: ${playlist.songIds.length}');
      expect(playlist.songIds, isNotEmpty);
    } catch (e, st) {
      print('Error loading album: $e');
      print(st);
      fail('Album loading failed');
    }
  });
}
