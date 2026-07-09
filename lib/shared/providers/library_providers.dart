import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/download_manager.dart';
import '../../core/services/library_manager.dart';
import '../../data/repositories/download_repository.dart';
import '../../shared/models/music_models.dart';
import 'backend_providers.dart';

// 1. Expose StorageService (initialized at boot and overridden)
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Override storageServiceProvider in ProviderScope');
});

// 2. Expose DownloadManager
final downloadManagerProvider = ChangeNotifierProvider<DownloadManager>((ref) {
  final resolver = ref.watch(streamResolverProvider);
  final repo = ref.watch(downloadRepositoryProvider);
  return DownloadManager(resolver, repo);
});

// 3. Expose LibraryManager
final libraryManagerProvider = ChangeNotifierProvider<LibraryManager>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return LibraryManager(storage: storage);
});

// 4. Expose downloaded songs from database reactively
final downloadedSongsProvider = FutureProvider<List<Song>>((ref) async {
  ref.watch(downloadManagerProvider); // trigger refresh on download updates
  final repo = ref.watch(downloadRepositoryProvider);
  return repo.getDownloadedSongs();
});

// 4. Expose Offline Mode state
final offlineModeProvider = StateProvider<bool>((ref) => false);
