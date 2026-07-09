import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/models/music_models.dart';
import 'session_manager.dart';
import 'logger_service.dart';

class AuthenticatedClient extends http.BaseClient {
  final String cookies;
  final http.Client _inner = http.Client();

  AuthenticatedClient(this.cookies);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Cookie'] = cookies;
    request.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    request.headers['x-youtube-client-name'] = '67';
    request.headers['x-youtube-client-version'] = '1.20250709.01.00';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

class YouTubeMusicAccountService {
  final SessionManager _sessionManager;

  bool get isLoggedIn => _sessionManager.isLoggedIn;
  String? get cookies => _sessionManager.cookies;
  AuthenticatedClient? get client => _sessionManager.client;

  static const String apiKey = "AIzaSyAo_JvSM59UN4us5UrT5D18Okkt5E-T24c";

  YouTubeMusicAccountService(this._sessionManager);

  Future<void> initialize() async {
    await _sessionManager.restoreSession();
  }

  Future<bool> login(String cookieHeader) async {
    return await _sessionManager.validateAndSaveSession(cookieHeader);
  }

  Future<void> logout() async {
    await _sessionManager.logout();
  }

  Future<Map<String, dynamic>?> _postBrowse(String browseId) async {
    if (!isLoggedIn || client == null) return null;

    try {
      final response = await client!.post(
        Uri.parse('https://music.youtube.com/youtubei/v1/browse?key=$apiKey&prettyPrint=false'),
        body: jsonEncode({
          "context": {
            "client": {
              "clientName": "WEB_REMIX",
              "clientVersion": "1.20250709.01.00",
              "hl": "en",
              "gl": "US"
            }
          },
          "browseId": browseId
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>?;
      }
    } catch (e) {
      DALogger.error('YouTubeMusicAccountService: Failed browse post request for $browseId', e);
    }
    return null;
  }

  Future<List<Song>> fetchLikedSongs() async {
    final data = await _postBrowse("FEmusic_liked_videos");
    if (data == null) return const [];
    return _parseSongsFromInnerTube(data);
  }

  Future<List<Playlist>> fetchLibraryPlaylists() async {
    final data = await _postBrowse("FEmusic_liked_playlists");
    if (data == null) return const [];
    return _parsePlaylistsFromInnerTube(data);
  }

  Future<List<Artist>> fetchLibraryArtists() async {
    final data = await _postBrowse("FEmusic_library_corpus_track_artists");
    if (data == null) return const [];
    return _parseArtistsFromInnerTube(data);
  }

  Future<List<Song>> fetchHistory() async {
    final data = await _postBrowse("FEmusic_history");
    if (data == null) return const [];
    return _parseSongsFromInnerTube(data);
  }

  Future<List<Song>> fetchPersonalizedRecommendations() async {
    final data = await _postBrowse("FEmusic_home");
    if (data == null) return const [];
    return _parseSongsFromInnerTube(data);
  }

  List<Song> _parseSongsFromInnerTube(Map<String, dynamic> json) {
    final List<Song> songs = [];

    void findSongs(dynamic node) {
      if (node is Map) {
        if (node.containsKey('musicResponsiveListItemRenderer')) {
          try {
            final renderer = node['musicResponsiveListItemRenderer'];
            final playlistItemData = renderer['playlistItemData'];
            final videoId = playlistItemData?['videoId'] as String?;
            if (videoId != null && videoId.isNotEmpty) {
              final flexColumns = renderer['flexColumns'] as List?;
              String title = 'Unknown Title';
              String artist = 'Unknown Artist';
              String album = 'Single';
              Duration duration = const Duration(minutes: 3);

              if (flexColumns != null && flexColumns.isNotEmpty) {
                final titleNode = flexColumns[0]['musicResponsiveListItemFlexColumnRenderer']['text']['runs'];
                if (titleNode is List && titleNode.isNotEmpty) {
                  title = titleNode[0]['text'] as String? ?? 'Unknown Title';
                }

                if (flexColumns.length > 1) {
                  final runs = flexColumns[1]['musicResponsiveListItemFlexColumnRenderer']['text']['runs'] as List?;
                  if (runs != null && runs.isNotEmpty) {
                    artist = runs[0]['text'] as String? ?? 'Unknown Artist';
                    if (runs.length > 2) {
                      album = runs[2]['text'] as String? ?? 'Single';
                    }
                  }
                }
              }

              String thumbnail = '';
              final thumbnails = renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
              if (thumbnails != null && thumbnails.isNotEmpty) {
                thumbnail = thumbnails.last['url'] as String? ?? '';
              }

              if (flexColumns != null && flexColumns.length > 2) {
                final runs = flexColumns[2]['musicResponsiveListItemFlexColumnRenderer']['text']['runs'] as List?;
                if (runs != null && runs.isNotEmpty) {
                  final durStr = runs[0]['text'] as String? ?? '';
                  duration = _parseDurationString(durStr);
                }
              }

              songs.add(Song(
                id: videoId,
                title: title,
                artist: artist,
                album: album,
                duration: duration,
                artworkUrl: thumbnail,
                source: 'youtube_music',
                lyrics: null,
              ));
            }
          } catch (_) {}
        } else {
          node.values.forEach(findSongs);
        }
      } else if (node is List) {
        node.forEach(findSongs);
      }
    }

    findSongs(json);
    return songs;
  }

  List<Playlist> _parsePlaylistsFromInnerTube(Map<String, dynamic> json) {
    final List<Playlist> playlists = [];

    void findPlaylists(dynamic node) {
      if (node is Map) {
        if (node.containsKey('playlistRenderer') || node.containsKey('musicTwoRowItemRenderer')) {
          try {
            final renderer = node['playlistRenderer'] ?? node['musicTwoRowItemRenderer'];
            final String? playlistId = renderer['playlistId'] ?? 
                renderer['navigationEndpoint']?['browseEndpoint']?['browseId'];
            
            if (playlistId != null && playlistId.isNotEmpty && (playlistId.startsWith('PL') || playlistId.startsWith('VL'))) {
              final titleText = renderer['title']?['runs']?[0]?['text'] ??
                  renderer['title']?['simpleText'] ?? 'Library Playlist';

              playlists.add(Playlist(
                id: playlistId,
                name: titleText,
                songs: const [],
              ));
            }
          } catch (_) {}
        }
        node.values.forEach(findPlaylists);
      } else if (node is List) {
        node.forEach(findPlaylists);
      }
    }

    findPlaylists(json);
    return playlists;
  }

  List<Artist> _parseArtistsFromInnerTube(Map<String, dynamic> json) {
    final List<Artist> artists = [];

    void findArtists(dynamic node) {
      if (node is Map) {
        if (node.containsKey('artistRenderer') || node.containsKey('musicTwoRowItemRenderer')) {
          try {
            final renderer = node['artistRenderer'] ?? node['musicTwoRowItemRenderer'];
            final String? artistId = renderer['navigationEndpoint']?['browseEndpoint']?['browseId'];
            
            if (artistId != null && artistId.isNotEmpty && (artistId.startsWith('UC') || artistId.contains('FEmusic_library_corpus_artist'))) {
              final titleText = renderer['title']?['runs']?[0]?['text'] ??
                  renderer['title']?['simpleText'] ?? 'Library Artist';

              String cover = '';
              final thumbnails = renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] ??
                  renderer['thumbnailRenderer']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'];
              if (thumbnails is List && thumbnails.isNotEmpty) {
                cover = thumbnails.last['url'] as String? ?? '';
              }

              artists.add(Artist(
                id: artistId,
                name: titleText,
                artworkUrl: cover,
              ));
            }
          } catch (_) {}
        }
        node.values.forEach(findArtists);
      } else if (node is List) {
        node.forEach(findArtists);
      }
    }

    findArtists(json);
    return artists;
  }

  Duration _parseDurationString(String durationStr) {
    if (durationStr.isEmpty) return const Duration(minutes: 3);
    final parts = durationStr.split(':');
    try {
      if (parts.length == 3) {
        return Duration(
          hours: int.parse(parts[0]),
          minutes: int.parse(parts[1]),
          seconds: int.parse(parts[2]),
        );
      } else if (parts.length == 2) {
        return Duration(
          minutes: int.parse(parts[0]),
          seconds: int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return const Duration(minutes: 3);
  }
}
