import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:da_music/main.dart' as app;
import 'package:da_music/shared/providers/player_providers.dart';
import 'package:da_music/shared/models/music_models.dart';
import 'package:da_music/shared/models/playback_state.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-End Real Audio Playback Pipeline Verification', (WidgetTester tester) async {
    // 1. Initialize and launch application
    app.main();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    // 2. Resolve Riverpod container and PlaybackController
    final container = ProviderScope.containerOf(tester.element(find.byType(app.DAMusicApp)));
    final controller = container.read(playbackControllerProvider);

    // 3. Verify the queue is empty and status is idle on startup in production
    debugPrint('Initial status at start: ${controller.status}');
    expect(controller.status, PlaybackStatus.idle);
    expect(controller.currentSong, isNull);
    debugPrint('Startup status verified as IDLE with empty queue.');

    // 4. Select Song A (SoundHelix Mock 1)
    const songA = Song(
      id: 'mock_asset_1',
      title: 'SoundHelix 1',
      artist: 'SoundHelix',
      album: 'Helix',
      duration: Duration(minutes: 6, seconds: 12),
      artworkUrl: null,
      source: 'youtube_music',
      lyrics: null,
    );

    debugPrint('Selecting Song A: ${songA.title}');
    await controller.selectSong(songA);
    await tester.pump();

    // 5. Wait for buffering to finish and transition to playing state
    int waitLoops = 60; // Wait up to 12 seconds
    while (controller.status == PlaybackStatus.loading && waitLoops > 0) {
      await tester.pump(const Duration(milliseconds: 200));
      waitLoops--;
    }

    debugPrint('Status after loading Song A: ${controller.status}');
    expect(controller.status, PlaybackStatus.playing);
    expect(controller.currentSong?.id, songA.id);

    // 6. Verify progress advances (audio is actively playing)
    debugPrint('Waiting for audio position to advance...');
    await tester.pump(const Duration(seconds: 4));
    debugPrint('Current position: ${controller.position.inMilliseconds}ms');
    expect(controller.position.inMilliseconds, greaterThan(0));

    // 7. Test Pause control
    debugPrint('Pausing Song A...');
    await controller.pause();
    await tester.pump();
    expect(controller.status, PlaybackStatus.paused);
    final pausedPosition = controller.position;

    // Verify position does not advance when paused
    await tester.pump(const Duration(seconds: 2));
    expect(controller.position, pausedPosition);
    debugPrint('Position correctly halted at: ${controller.position.inMilliseconds}ms');

    // 8. Test Resume control
    debugPrint('Resuming Song A...');
    await controller.resume();
    await tester.pump();
    expect(controller.status, PlaybackStatus.playing);

    // 9. Select Song B (SoundHelix Mock 2) and verify it stops Song A
    const songB = Song(
      id: 'mock_asset_2',
      title: 'SoundHelix 2',
      artist: 'SoundHelix',
      album: 'Helix',
      duration: Duration(minutes: 7, seconds: 5),
      artworkUrl: null,
      source: 'youtube_music',
      lyrics: null,
    );

    debugPrint('Selecting Song B: ${songB.title}');
    await controller.selectSong(songB);
    await tester.pump();

    // Wait for buffering to finish for Song B
    waitLoops = 60;
    while (controller.status == PlaybackStatus.loading && waitLoops > 0) {
      await tester.pump(const Duration(milliseconds: 200));
      waitLoops--;
    }

    debugPrint('Status after switching: ${controller.status}');
    expect(controller.status, PlaybackStatus.playing);
    expect(controller.currentSong?.id, songB.id);

    // Let it play briefly
    await tester.pump(const Duration(seconds: 2));
    debugPrint('Playback successfully verified for both tracks.');

    // 10. Pause to stop the audioplayers position update timers and clean up
    debugPrint('Stopping playback for test cleanup...');
    await controller.pause();
    await tester.pumpAndSettle();
  });
}
