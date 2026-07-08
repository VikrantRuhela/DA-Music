import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/download_manager.dart';
import '../../core/services/library_manager.dart';

// 1. Expose StorageService (initialized at boot and overridden)
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Override storageServiceProvider in ProviderScope');
});

// 2. Expose DownloadManager
final downloadManagerProvider = ChangeNotifierProvider<DownloadManager>((ref) {
  return DownloadManager();
});

// 3. Expose LibraryManager
final libraryManagerProvider = ChangeNotifierProvider<LibraryManager>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return LibraryManager(storage: storage);
});

// 4. Expose Offline Mode state
final offlineModeProvider = StateProvider<bool>((ref) => false);
