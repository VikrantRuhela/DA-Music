import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/playback_controller.dart';
import '../models/music_models.dart';
import '../models/playback_state.dart';
import 'backend_providers.dart';

// StateProvider from Sprint 4
final immersiveModeProvider = StateProvider<bool>((ref) => false);

// 1. Playback Controller Provider (ChangeNotifierProvider)
final playbackControllerProvider = ChangeNotifierProvider<PlaybackController>((ref) {
  final engine = ref.watch(playbackEngineProvider);
  final sourceManager = ref.watch(sourceManagerProvider);
  final artistRepo = ref.watch(artistRepositoryProvider);
  final albumRepo = ref.watch(albumRepositoryProvider);
  final recommendationRepo = ref.watch(recommendationRepositoryProvider);
  return PlaybackController(
    engine,
    sourceManager,
    artistRepo,
    albumRepo,
    recommendationRepo,
  );
});

// 2. Playback State Provider (Watching status from controller)
final playbackStateProvider = Provider<PlaybackState>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return PlaybackState(
    status: controller.status,
    bufferingProgress: controller.bufferProgress,
  );
});

// 3. Current Song Provider (Watching active song from controller)
final currentSongProvider = Provider<Song?>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.currentSong;
});

// 4. Volume Provider (Watching volume setting from controller)
final volumeProvider = Provider<int>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.settings.volume;
});

// 5. Mute Provider (Watching mute setting from controller)
final muteProvider = Provider<bool>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.settings.isMuted;
});

// 6. Repeat Mode Provider
final repeatModeProvider = Provider<RepeatMode>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.settings.repeatMode;
});

// 7. Shuffle Provider
final shuffleProvider = Provider<bool>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.settings.isShuffle;
});

// 8. Queue Provider
final queueProvider = Provider<List<QueueItem>>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.queue;
});
