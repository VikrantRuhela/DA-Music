import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/source_manager.dart';
import '../../core/services/youtube_music_adapter.dart';
import '../../core/services/source_adapter.dart';

// 1. Expose the SourceManager singleton
final sourceManagerProvider = Provider<SourceManager>((ref) {
  final manager = SourceManager();

  // Register YouTube Music Adapter immediately
  final ytAdapter = YouTubeMusicAdapter();
  manager.registerAdapter(ytAdapter);

  // Set as active adapter (synchronously or inside build)
  manager.selectSource(ytAdapter.id);

  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

// 2. Expose the currently active source adapter
final activeSourceAdapterProvider = Provider<MusicSourceAdapter>((ref) {
  final manager = ref.watch(sourceManagerProvider);
  return manager.activeAdapter;
});
