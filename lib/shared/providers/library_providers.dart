import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/download_manager.dart';
import '../../core/services/library_manager.dart';
import '../../data/repositories/download_repository.dart';
import '../../shared/models/music_models.dart';
import '../../features/local_library/data/local_library_repository.dart';
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

// 5. Expose Album Art Background setting state
final showAlbumArtBackgroundProvider = StateNotifierProvider<ShowAlbumArtBackgroundNotifier, bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ShowAlbumArtBackgroundNotifier(storage);
});

class ShowAlbumArtBackgroundNotifier extends StateNotifier<bool> {
  final StorageService _storage;
  static const _key = 'show_album_art_background';

  ShowAlbumArtBackgroundNotifier(this._storage) : super(false) {
    _load();
  }

  void _load() async {
    final val = await _storage.getString(_key);
    state = val == 'true';
  }

  Future<void> toggle(bool val) async {
    state = val;
    await _storage.setString(_key, val.toString());
  }
}

// 6. Unified Library Providers (Deduplicated)
final unifiedSongsProvider = FutureProvider<List<Song>>((ref) async {
  final localSongs = ref.watch(localLibraryRepositoryProvider).songs;
  final downloadedSongs = await ref.watch(downloadedSongsProvider.future);
  final localLiked = ref.watch(libraryManagerProvider).likedSongs;
  
  final syncManager = ref.watch(ytmSyncManagerProvider);
  final ytmSongs = await syncManager.getCachedLikedSongs();

  final List<Song> merged = [...localSongs, ...downloadedSongs, ...localLiked, ...ytmSongs];
  final Set<String> seenIds = {};
  final Set<String> seenTitles = {};
  final List<Song> deduplicated = [];

  for (final song in merged) {
    final titleKey = '${song.title.toLowerCase()}|${song.artist.toLowerCase()}';
    if (!seenIds.contains(song.id) && !seenTitles.contains(titleKey)) {
      seenIds.add(song.id);
      seenTitles.add(titleKey);
      deduplicated.add(song);
    }
  }
  return deduplicated;
});

final unifiedPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final localPlaylists = ref.watch(libraryManagerProvider).playlists;
  final syncManager = ref.watch(ytmSyncManagerProvider);
  final ytmPlaylists = await syncManager.getCachedPlaylists();

  final List<Playlist> merged = [];
  
  // Local playlists
  for (final lp in localPlaylists) {
    merged.add(Playlist(
      id: lp.id,
      name: lp.name,
      songs: lp.songs,
    ));
  }

  // YTM playlists (deduplicated by name)
  final Set<String> seenNames = merged.map((p) => p.name.toLowerCase()).toSet();
  for (final p in ytmPlaylists) {
    if (!seenNames.contains(p.name.toLowerCase())) {
      merged.add(p);
      seenNames.add(p.name.toLowerCase());
    }
  }
  return merged;
});

final unifiedAlbumsProvider = FutureProvider<List<Album>>((ref) async {
  final localAlbums = ref.watch(localLibraryRepositoryProvider.notifier).getAlbums();
  final syncManager = ref.watch(ytmSyncManagerProvider);
  final ytmAlbums = await syncManager.getCachedAlbums();

  final List<Album> merged = [...localAlbums];
  final Set<String> seenKeys = localAlbums.map((a) => '${a.name.toLowerCase()}|${a.artist.toLowerCase()}').toSet();

  for (final a in ytmAlbums) {
    final key = '${a.name.toLowerCase()}|${a.artist.toLowerCase()}';
    if (!seenKeys.contains(key)) {
      merged.add(a);
      seenKeys.add(key);
    }
  }
  return merged;
});

final unifiedArtistsProvider = FutureProvider<List<Artist>>((ref) async {
  final localArtists = ref.watch(localLibraryRepositoryProvider.notifier).getArtists();
  final syncManager = ref.watch(ytmSyncManagerProvider);
  final ytmArtists = await syncManager.getCachedArtists();

  final List<Artist> merged = [...localArtists];
  final Set<String> seenNames = localArtists.map((a) => a.name.toLowerCase()).toSet();

  for (final a in ytmArtists) {
    if (!seenNames.contains(a.name.toLowerCase())) {
      merged.add(a);
      seenNames.add(a.name.toLowerCase());
    }
  }
  return merged;
});
