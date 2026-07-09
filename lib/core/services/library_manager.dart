import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'youtube_music_account_service.dart';
import '../../shared/models/music_models.dart';

class LibraryPlaylist {
  final String id;
  final String name;
  final List<Song> songs;

  LibraryPlaylist({
    required this.id,
    required this.name,
    required this.songs,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'songs': songs.map((s) => s.toJson()).toList(),
      };

  factory LibraryPlaylist.fromJson(Map<String, dynamic> json) => LibraryPlaylist(
        id: json['id'] as String,
        name: json['name'] as String,
        songs: (json['songs'] as List<dynamic>)
            .map((s) => Song.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class LibraryManager extends ChangeNotifier {
  final StorageService _storage;

  final List<Song> _likedSongs = [];
  final List<Album> _likedAlbums = [];
  final List<Artist> _likedArtists = [];
  final List<Song> _history = [];
  final List<LibraryPlaylist> _playlists = [];

  final Map<String, int> _playCounts = {};
  final Map<String, int> _skipCounts = {};
  final Map<String, int> _listeningSeconds = {};

  LibraryManager({required this._storage}) {
    _loadFromStorage();
  }

  List<Song> get likedSongs => List.unmodifiable(_likedSongs);
  List<Album> get likedAlbums => List.unmodifiable(_likedAlbums);
  List<Artist> get likedArtists => List.unmodifiable(_likedArtists);
  List<Song> get history => List.unmodifiable(_history);
  List<LibraryPlaylist> get playlists => List.unmodifiable(_playlists);

  static const String _keyLikedSongs = 'lib_liked_songs';
  static const String _keyLikedAlbums = 'lib_liked_albums';
  static const String _keyLikedArtists = 'lib_liked_artists';
  static const String _keyHistory = 'lib_history';
  static const String _keyPlaylists = 'lib_playlists';
  static const String _keyStatsPlay = 'lib_stats_play';
  static const String _keyStatsSkip = 'lib_stats_skip';

  Future<void> _loadFromStorage() async {
    try {
      final likedSongsJson = await _storage.getString(_keyLikedSongs);
      if (likedSongsJson != null) {
        final List<dynamic> list = jsonDecode(likedSongsJson);
        _likedSongs.clear();
        _likedSongs.addAll(list.map((s) => Song.fromJson(s as Map<String, dynamic>)));
      }

      final likedAlbumsJson = await _storage.getString(_keyLikedAlbums);
      if (likedAlbumsJson != null) {
        final List<dynamic> list = jsonDecode(likedAlbumsJson);
        _likedAlbums.clear();
        _likedAlbums.addAll(list.map((a) => Album.fromJson(a as Map<String, dynamic>)));
      }

      final likedArtistsJson = await _storage.getString(_keyLikedArtists);
      if (likedArtistsJson != null) {
        final List<dynamic> list = jsonDecode(likedArtistsJson);
        _likedArtists.clear();
        _likedArtists.addAll(list.map((a) => Artist.fromJson(a as Map<String, dynamic>)));
      }

      final historyJson = await _storage.getString(_keyHistory);
      if (historyJson != null) {
        final List<dynamic> list = jsonDecode(historyJson);
        _history.clear();
        _history.addAll(list.map((s) => Song.fromJson(s as Map<String, dynamic>)));
      }

      final playlistsJson = await _storage.getString(_keyPlaylists);
      if (playlistsJson != null) {
        final List<dynamic> list = jsonDecode(playlistsJson);
        _playlists.clear();
        _playlists.addAll(list.map((p) => LibraryPlaylist.fromJson(p as Map<String, dynamic>)));
      }

      final statsPlayJson = await _storage.getString(_keyStatsPlay);
      if (statsPlayJson != null) {
        _playCounts.clear();
        _playCounts.addAll(Map<String, int>.from(jsonDecode(statsPlayJson)));
      }

      final statsSkipJson = await _storage.getString(_keyStatsSkip);
      if (statsSkipJson != null) {
        _skipCounts.clear();
        _skipCounts.addAll(Map<String, int>.from(jsonDecode(statsSkipJson)));
      }
      notifyListeners();
    } catch (e) {
      debugPrint(' [Library Manager] Failed to load library data: $e');
    }
  }

  Future<void> _save() async {
    try {
      await _storage.setString(_keyLikedSongs, jsonEncode(_likedSongs.map((s) => s.toJson()).toList()));
      await _storage.setString(_keyLikedAlbums, jsonEncode(_likedAlbums.map((a) => a.toJson()).toList()));
      await _storage.setString(_keyLikedArtists, jsonEncode(_likedArtists.map((a) => a.toJson()).toList()));
      await _storage.setString(_keyHistory, jsonEncode(_history.map((s) => s.toJson()).toList()));
      await _storage.setString(_keyPlaylists, jsonEncode(_playlists.map((p) => p.toJson()).toList()));
      await _storage.setString(_keyStatsPlay, jsonEncode(_playCounts));
      await _storage.setString(_keyStatsSkip, jsonEncode(_skipCounts));
    } catch (e) {
      debugPrint(' [Library Manager] Failed to save library data: $e');
    }
  }

  void toggleLikeSong(Song song) {
    final index = _likedSongs.indexWhere((s) => s.id == song.id);
    if (index >= 0) {
      _likedSongs.removeAt(index);
      debugPrint(' [Library Manager] Unliked song: ${song.title}');
    } else {
      _likedSongs.add(song);
      debugPrint(' [Library Manager] Liked song: ${song.title}');
    }
    _save();
    notifyListeners();
  }

  bool isSongLiked(String id) => _likedSongs.any((s) => s.id == id);

  void toggleLikeAlbum(Album album) {
    final index = _likedAlbums.indexWhere((a) => a.id == album.id);
    if (index >= 0) {
      _likedAlbums.removeAt(index);
    } else {
      _likedAlbums.add(album);
    }
    _save();
    notifyListeners();
  }

  void toggleLikeArtist(Artist artist) {
    final index = _likedArtists.indexWhere((a) => a.id == artist.id);
    if (index >= 0) {
      _likedArtists.removeAt(index);
    } else {
      _likedArtists.add(artist);
    }
    _save();
    notifyListeners();
  }

  void addToHistory(Song song) {
    _history.removeWhere((s) => s.id == song.id);
    _history.insert(0, song);
    if (_history.length > 50) {
      _history.removeLast();
    }

    _playCounts[song.id] = (_playCounts[song.id] ?? 0) + 1;
    debugPrint(' [Library Manager] Added history log for: ${song.title}. Play count: ${_playCounts[song.id]}');
    _save();
    notifyListeners();
  }

  void trackSkip(String songId) {
    _skipCounts[songId] = (_skipCounts[songId] ?? 0) + 1;
    _save();
  }

  void trackListeningSeconds(String songId, int seconds) {
    _listeningSeconds[songId] = (_listeningSeconds[songId] ?? 0) + seconds;
    notifyListeners();
  }

  int getPlayCount(String songId) => _playCounts[songId] ?? 0;
  int getSkipCount(String songId) => _skipCounts[songId] ?? 0;

  void createPlaylist(String name) {
    final playlist = LibraryPlaylist(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      songs: [],
    );
    _playlists.add(playlist);
    debugPrint(' [Library Manager] Created playlist: $name');
    _save();
    notifyListeners();
  }

  void renamePlaylist(String id, String newName) {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index >= 0) {
      _playlists[index] = LibraryPlaylist(
        id: id,
        name: newName,
        songs: _playlists[index].songs,
      );
      _save();
      notifyListeners();
    }
  }

  void deletePlaylist(String id) {
    _playlists.removeWhere((p) => p.id == id);
    _save();
    notifyListeners();
  }

  void addSongToPlaylist(String playlistId, Song song) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index >= 0) {
      final playlist = _playlists[index];
      if (!playlist.songs.any((s) => s.id == song.id)) {
        playlist.songs.add(song);
        debugPrint(' [Library Manager] Added song ${song.title} to playlist ${playlist.name}');
        _save();
        notifyListeners();
      }
    }
  }

  void removeSongFromPlaylist(String playlistId, String songId) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index >= 0) {
      _playlists[index].songs.removeWhere((s) => s.id == songId);
      _save();
      notifyListeners();
    }
  }

  List<Song> searchLocal(String query) {
    if (query.isEmpty) return likedSongs;
    final term = query.toLowerCase();

    final results = <Song>{};
    for (final song in _likedSongs) {
      if (song.title.toLowerCase().contains(term) || song.artist.toLowerCase().contains(term)) {
        results.add(song);
      }
    }

    for (final playlist in _playlists) {
      for (final song in playlist.songs) {
        if (song.title.toLowerCase().contains(term) || song.artist.toLowerCase().contains(term)) {
          results.add(song);
        }
      }
    }

    return results.toList();
  }

  Future<void> syncWithYouTubeMusic(YouTubeMusicAccountService accountService) async {
    if (!accountService.isLoggedIn) return;

    try {
      // 1. Sync Liked Songs
      final remoteLikes = await accountService.fetchLikedSongs();
      if (remoteLikes.isNotEmpty) {
        final Set<String> existingIds = _likedSongs.map((s) => s.id).toSet();
        for (final song in remoteLikes) {
          if (!existingIds.contains(song.id)) {
            _likedSongs.add(song);
            existingIds.add(song.id);
          }
        }
      }

      // 2. Sync Playlists
      final remotePlaylists = await accountService.fetchLibraryPlaylists();
      if (remotePlaylists.isNotEmpty) {
        final Set<String> existingNames = _playlists.map((p) => p.name.toLowerCase()).toSet();
        for (final p in remotePlaylists) {
          if (!existingNames.contains(p.name.toLowerCase())) {
            _playlists.add(LibraryPlaylist(
              id: p.id,
              name: p.name,
              songs: const [],
            ));
          }
        }
      }

      // 3. Sync Artists
      final remoteArtists = await accountService.fetchLibraryArtists();
      if (remoteArtists.isNotEmpty) {
        final Set<String> existingNames = _likedArtists.map((a) => a.name.toLowerCase()).toSet();
        for (final a in remoteArtists) {
          if (!existingNames.contains(a.name.toLowerCase())) {
            _likedArtists.add(Artist(
              id: a.id,
              name: a.name,
              artworkUrl: a.artworkUrl,
            ));
          }
        }
      }

      // 4. Sync History
      final remoteHistory = await accountService.fetchHistory();
      if (remoteHistory.isNotEmpty) {
        final Set<String> existingIds = _history.map((s) => s.id).toSet();
        for (final song in remoteHistory) {
          if (!existingIds.contains(song.id)) {
            _history.insert(0, song);
            existingIds.add(song.id);
          }
        }
      }

      await _save();
      notifyListeners();
    } catch (_) {}
  }
}
