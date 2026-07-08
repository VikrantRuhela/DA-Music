import 'package:flutter_test/flutter_test.dart';
import 'package:da_music/core/services/youtube_music_adapter.dart';

void main() {
  test('Compare getSong vs artist top song', () async {
    final adapter = YouTubeMusicAdapter();
    await adapter.initialize();

    const artistId = 'UCT9zcQNlyht7fRlcjmflRSA'; // Imagine Dragons
    const targetSongId = 'Kx7B-XvmFtE'; // Believer

    print('Fetching artist top songs...');
    final artist = await adapter.getArtist(artistId);
    final artistSongs = adapter.getArtistSongs(artistId);
    final artistSong = artistSongs.firstWhere((s) => s.id == targetSongId);

    print('Fetching song by ID: $targetSongId...');
    final resolvedSong = await adapter.getSong(targetSongId);

    print('\n--- Comparison ---');
    print('Resolved Song:');
    print('  id: ${resolvedSong.id}');
    print('  sourceId: ${resolvedSong.sourceId}');
    print('  albumId: ${resolvedSong.albumId}');
    print('  artwork url: ${resolvedSong.artwork.url}');

    print('Artist Top Song:');
    print('  id: ${artistSong.id}');
    print('  sourceId: ${artistSong.sourceId}');
    print('  albumId: ${artistSong.albumId}');
    print('  artwork url: ${artistSong.artwork.url}');

    expect(artistSong.id, resolvedSong.id);
    expect(artistSong.sourceId, resolvedSong.sourceId);
    expect(artistSong.albumId, resolvedSong.albumId);
  });
}
