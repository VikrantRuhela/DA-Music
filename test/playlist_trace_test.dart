import 'package:flutter_test/flutter_test.dart';
import 'package:da_music/core/services/youtube_music_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Trace real exception for playlist loading', () async {
    const playlistId = 'PL4fGSI1pDJn6O1LS0XSdF3RyO0Rq_LDeI';
    print('\n================ REAL EXCEPTION TRACE START ================');
    print('Testing playlistId: $playlistId');

    final adapter = YouTubeMusicAdapter();
    await adapter.initialize();

    try {
      final playlist = await adapter.getPlaylist(playlistId);
      print('SUCCESS! Playlist loaded:');
      print('  id: ${playlist.id}');
      print('  title: "${playlist.title}"');
      print('  owner: "${playlist.owner}"');
      print('  songIds.length: ${playlist.songIds.length}');
    } catch (e, stack) {
      print('\n=== CATCH BLOCK IN TEST ===');
      print('Exception: $e');
      print('Stack:\n$stack');
    } finally {
      await adapter.dispose();
      print('================ REAL EXCEPTION TRACE END ==================\n');
    }
  });
}
