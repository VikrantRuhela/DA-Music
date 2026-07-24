import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/playback_controller.dart';
import '../../core/services/storage_service.dart';
import '../models/music_models.dart';
import '../models/playback_state.dart';
import 'backend_providers.dart';
import 'library_providers.dart';

final immersiveModeProvider = StateProvider<bool>((ref) => false);

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

final playbackStateProvider = Provider<PlaybackState>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return PlaybackState(
    status: controller.status,
    bufferingProgress: controller.bufferProgress,
  );
});

final currentSongProvider = Provider<Song?>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.currentSong;
});

final volumeProvider = Provider<int>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.settings.volume;
});

final muteProvider = Provider<bool>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.settings.isMuted;
});

final repeatModeProvider = Provider<RepeatMode>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.settings.repeatMode;
});

final shuffleProvider = Provider<bool>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.settings.isShuffle;
});

final queueProvider = Provider<List<QueueItem>>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.queue;
});

final sleepTimerProvider = StateProvider<Timer?>((ref) => null);
final sleepTimerDurationProvider = StateProvider<Duration?>((ref) => null);

enum PlayerStyle { immersive, vinyl, minimal }

final playerStyleProvider = StateNotifierProvider<PlayerStyleNotifier, PlayerStyle>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return PlayerStyleNotifier(storage);
});

class PlayerStyleNotifier extends StateNotifier<PlayerStyle> {
  final StorageService _storage;
  static const _key = 'player_style';

  PlayerStyleNotifier(this._storage) : super(PlayerStyle.vinyl) {
    _load();
  }

  void _load() async {
    final val = await _storage.getString(_key);
    if (val != null) {
      final matched = PlayerStyle.values.firstWhere(
        (e) => e.name == val,
        orElse: () => PlayerStyle.vinyl,
      );
      state = matched;
    }
  }

  Future<void> setStyle(PlayerStyle style) async {
    state = style;
    await _storage.setString(_key, style.name);
  }
}
