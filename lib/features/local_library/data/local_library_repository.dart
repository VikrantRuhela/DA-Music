import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../shared/models/music_models.dart';
import '../../../core/services/logger_service.dart';
import '../domain/local_metadata_parser.dart';

class LocalLibraryState {
  final List<String> folders;
  final List<Song> songs;
  final Map<String, Map<String, dynamic>> hiResInfoMap; // songId -> hiRes properties
  final bool autoScan;
  final bool isScanning;
  final double scanProgress; // 0.0 to 1.0

  const LocalLibraryState({
    this.folders = const [],
    this.songs = const [],
    this.hiResInfoMap = const {},
    this.autoScan = false,
    this.isScanning = false,
    this.scanProgress = 0.0,
  });

  LocalLibraryState copyWith({
    List<String>? folders,
    List<Song>? songs,
    Map<String, Map<String, dynamic>>? hiResInfoMap,
    bool? autoScan,
    bool? isScanning,
    double? scanProgress,
  }) {
    return LocalLibraryState(
      folders: folders ?? this.folders,
      songs: songs ?? this.songs,
      hiResInfoMap: hiResInfoMap ?? this.hiResInfoMap,
      autoScan: autoScan ?? this.autoScan,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
    );
  }
}

class LocalLibraryRepository extends StateNotifier<LocalLibraryState> {
  LocalLibraryRepository() : super(const LocalLibraryState()) {
    _loadFromStorage();
  }

  static const _fileName = 'local_library.json';

  Future<File> get _file async {
    final docDir = await getApplicationDocumentsDirectory();
    return File(p.join(docDir.path, _fileName));
  }

  Future<void> _loadFromStorage() async {
    try {
      final f = await _file;
      List<String> defaultFolders = [];
      if (Platform.isAndroid) {
        defaultFolders = ['/storage/emulated/0/Music', '/storage/emulated/0/Download'];
      } else if (Platform.isWindows) {
        final home = Platform.environment['USERPROFILE'];
        if (home != null) {
          defaultFolders = [p.join(home, 'Music')];
        }
      }

      if (!await f.exists()) {
        state = state.copyWith(folders: defaultFolders);
        await _saveToStorage();
        if (state.autoScan) {
          scanFolders();
        }
        return;
      }
      final jsonStr = await f.readAsString();
      final data = json.decode(jsonStr) as Map<String, dynamic>;

      var folders = List<String>.from(data['folders'] ?? []);
      if (folders.isEmpty) {
        folders = defaultFolders;
      }
      final songsList = (data['songs'] as List? ?? [])
          .map((item) => Song.fromJson(item as Map<String, dynamic>))
          .toList();
      
      final hiResMap = (data['hiResInfoMap'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));

      final autoScan = data['autoScan'] as bool? ?? false;

      state = state.copyWith(
        folders: folders,
        songs: songsList,
        hiResInfoMap: hiResMap,
        autoScan: autoScan,
      );

      if (autoScan && folders.isNotEmpty) {
        scanFolders();
      }
    } catch (e, stack) {
      DALogger.error('LocalLibraryRepository: Failed to load from storage', e, stack);
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final f = await _file;
      final data = {
        'folders': state.folders,
        'songs': state.songs.map((s) => s.toJson()).toList(),
        'hiResInfoMap': state.hiResInfoMap,
        'autoScan': state.autoScan,
      };
      await f.writeAsString(json.encode(data));
    } catch (e, stack) {
      DALogger.error('LocalLibraryRepository: Failed to save to storage', e, stack);
    }
  }

  Future<void> addFolder(String path) async {
    if (state.folders.contains(path)) return;
    state = state.copyWith(folders: [...state.folders, path]);
    await _saveToStorage();
    await scanFolders();
  }

  Future<void> removeFolder(String path) async {
    final updatedFolders = state.folders.where((f) => f != path).toList();
    // Also remove any songs that belong to that folder path prefix
    final updatedSongs = state.songs.where((s) => !s.id.startsWith(path)).toList();
    
    final updatedHiRes = Map<String, Map<String, dynamic>>.from(state.hiResInfoMap);
    updatedHiRes.removeWhere((k, v) => !k.startsWith(path));

    state = state.copyWith(
      folders: updatedFolders,
      songs: updatedSongs,
      hiResInfoMap: updatedHiRes,
    );
    await _saveToStorage();
  }

  Future<void> toggleAutoScan(bool enable) async {
    state = state.copyWith(autoScan: enable);
    await _saveToStorage();
  }

  Future<void> scanFolders() async {
    if (state.isScanning || state.folders.isEmpty) return;
    
    state = state.copyWith(isScanning: true, scanProgress: 0.0);
    DALogger.info('LocalLibraryRepository: Starting library folders scan...');

    final List<String> audioFilePaths = [];
    final supportedExtensions = {
      '.mp3', '.flac', '.wav', '.m4a', '.aac', '.ogg', '.opus', '.aiff', '.aif'
    };

    // 1. Gather all file paths in scanned folders recursively using async stream
    for (final folderPath in state.folders) {
      try {
        final dir = Directory(folderPath);
        if (await dir.exists()) {
          await for (final entity in dir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              final ext = p.extension(entity.path).toLowerCase();
              if (supportedExtensions.contains(ext)) {
                audioFilePaths.add(entity.path);
              }
            }
          }
        }
      } catch (e) {
        DALogger.warning('LocalLibraryRepository: Folder list failed for $folderPath: $e');
      }
    }

    if (audioFilePaths.isEmpty) {
      state = state.copyWith(isScanning: false, scanProgress: 1.0);
      return;
    }

    // 2. Scan each file incrementally, checking if we already parsed it
    final List<Song> updatedSongs = List.from(state.songs);
    final Map<String, Map<String, dynamic>> updatedHiRes = Map.from(state.hiResInfoMap);
    
    // Get docDirPath on main thread
    final docDir = await getApplicationDocumentsDirectory();
    final docDirPath = docDir.path;

    // Create quick lookup set
    final existingPaths = updatedSongs.map((s) => s.id).toSet();
    
    int processedCount = 0;
    for (final path in audioFilePaths) {
      if (existingPaths.contains(path)) {
        processedCount++;
        state = state.copyWith(scanProgress: processedCount / audioFilePaths.length);
        continue;
      }

      // Read metadata & cover art in background isolate
      final song = await LocalMetadataParser.parseFile(path, docDirPath);
      if (song != null) {
        updatedSongs.add(song);
        
        // Also parse Hi-Res audio specifications in background isolate
        try {
          final fileInfo = await LocalMetadataParser.parseHiResAudioInfo(File(path));
          updatedHiRes[path] = fileInfo;
        } catch (_) {}
      }

      processedCount++;
      state = state.copyWith(scanProgress: processedCount / audioFilePaths.length);

      // Yield execution to prevent UI locks
      await Future.delayed(const Duration(milliseconds: 5));
    }

    // Filter out files that were deleted from folders since last scan
    final currentPathsSet = audioFilePaths.toSet();
    final finalSongs = updatedSongs.where((s) => currentPathsSet.contains(s.id)).toList();
    updatedHiRes.removeWhere((k, v) => !currentPathsSet.contains(k));

    state = state.copyWith(
      songs: finalSongs,
      hiResInfoMap: updatedHiRes,
      isScanning: false,
      scanProgress: 1.0,
    );
    await _saveToStorage();
    DALogger.info('LocalLibraryRepository: Scanning completed. Scanned ${finalSongs.length} local files.');
  }

  // Structural getters mapping scanned data
  List<Album> getAlbums() {
    final Map<String, List<Song>> albumSongs = {};
    for (final song in state.songs) {
      albumSongs.putIfAbsent(song.album, () => []).add(song);
    }
    return albumSongs.entries.map((e) {
      final firstSong = e.value.first;
      return Album(
        id: e.key,
        name: e.key,
        artist: firstSong.artist,
        artworkUrl: firstSong.artworkUrl,
        songs: e.value,
      );
    }).toList();
  }

  List<Artist> getArtists() {
    final Map<String, List<Song>> artistSongs = {};
    for (final song in state.songs) {
      artistSongs.putIfAbsent(song.artist, () => []).add(song);
    }
    return artistSongs.entries.map((e) {
      final firstSong = e.value.first;
      return Artist(
        id: e.key,
        name: e.key,
        artworkUrl: firstSong.artworkUrl,
      );
    }).toList();
  }

  List<String> getGenres() {
    final Set<String> genres = {};
    // Fallback to basic genres or read from file system
    // (audio_metadata_reader doesn't always expose genre, so we default to 'Local')
    if (state.songs.isNotEmpty) {
      genres.add('Local');
    }
    return genres.toList();
  }

  List<Song> getHiResSongs() {
    return state.songs.where((s) {
      final info = state.hiResInfoMap[s.id];
      return info != null && (info['isHiRes'] as bool? ?? false);
    }).toList();
  }

  List<Song> getRecentlyAdded() {
    final List<Song> list = List.from(state.songs);
    list.sort((a, b) {
      final infoA = state.hiResInfoMap[a.id];
      final infoB = state.hiResInfoMap[b.id];
      final modA = infoA?['modifiedAt'] as int? ?? 0;
      final modB = infoB?['modifiedAt'] as int? ?? 0;
      return modB.compareTo(modA); // newest first
    });
    return list;
  }

  List<Song> search(String query) {
    if (query.trim().isEmpty) return [];
    final lq = query.toLowerCase();
    return state.songs.where((s) {
      return s.title.toLowerCase().contains(lq) ||
          s.artist.toLowerCase().contains(lq) ||
          s.album.toLowerCase().contains(lq);
    }).toList();
  }
}

// Expose the repository via Riverpod
final localLibraryRepositoryProvider =
    StateNotifierProvider<LocalLibraryRepository, LocalLibraryState>((ref) {
  return LocalLibraryRepository();
});
