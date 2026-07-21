import 'package:da_music/core/services/youtube_music_adapter.dart';

Future<void> main(List<String> args) async {
  final playlistId = args.isNotEmpty ? args[0] : 'PL4fGSI1pDJn6O1LS0XSdF3RyO0Rq_LDeI';
  print('Testing _fetchPlaylistDetails for ID: $playlistId');

  final adapter = YouTubeMusicAdapter();
  await adapter.initialize();

  try {
    final playlist = await adapter.getPlaylist(playlistId);
    print('SUCCESS! Playlist loaded:');
    print('  ID: ${playlist.id}');
    print('  Title: "${playlist.title}"');
    print('  Owner: "${playlist.owner}"');
    print('  Song Count: ${playlist.songIds.length}');
  } catch (e, stack) {
    print('ERROR CAUGHT: $e');
    print('STACK TRACE:\n$stack');
  } finally {
    await adapter.dispose();
  }
}
