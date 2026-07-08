import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'source_adapter.dart';
import '../exceptions/playback_exceptions.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/value_objects.dart';
import 'logger_service.dart';

/// Concrete YouTube Music source adapter mapping remote API details to pure Domain entities.
class YouTubeMusicAdapter implements MusicSourceAdapter {
  bool _isInitialized = false;
  late yt.YoutubeExplode _ytClient;
  final Map<String, Song> _songCache = {};

  void cacheSongForTesting(Song song) {
    _songCache[song.id] = song;
  }

  // Caches for artist details
  final Map<String, List<Song>> _artistSongs = {};
  final Map<String, List<Album>> _artistAlbums = {};
  final Map<String, List<Album>> _artistSingles = {};
  final Map<String, List<Playlist>> _artistPlaylists = {};
  final Map<String, List<Artist>> _artistRelated = {};

  @override
  List<Song> getArtistSongs(String artistId) => _artistSongs[artistId] ?? const [];

  @override
  List<Album> getArtistAlbums(String artistId) => _artistAlbums[artistId] ?? const [];

  @override
  List<Album> getArtistSingles(String artistId) => _artistSingles[artistId] ?? const [];

  @override
  List<Playlist> getArtistPlaylists(String artistId) => _artistPlaylists[artistId] ?? const [];

  @override
  List<Artist> getArtistRelated(String artistId) => _artistRelated[artistId] ?? const [];

  @override
  String get id => 'youtube_music';

  @override
  String get name => 'YouTube Music';

  void _checkInitialized() {
    if (!_isInitialized) {
      throw const SourceException('YouTube Music Adapter not initialized. Call initialize() first.');
    }
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    _ytClient = yt.YoutubeExplode();
    _isInitialized = true;
    DALogger.info('YouTubeMusicAdapter: YoutubeExplode client initialized.');
  }

  @override
  Future<void> dispose() async {
    if (!_isInitialized) return;
    _ytClient.close();
    _isInitialized = false;
    DALogger.info('YouTubeMusicAdapter: YoutubeExplode client closed.');
  }

  Duration _parseDuration(String durationStr) {
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
    } catch (_) {
      // Fallback on parsing exceptions
    }
    return const Duration(minutes: 3);
  }

  @override
  Future<SearchResult> search(String query) async {
    _checkInitialized();
    DALogger.info('YouTubeMusicAdapter: Searching for "$query"');

    try {
      final results = await _ytClient.search.searchContent(query);

      final songs = <Song>[];
      final albums = <Album>[];
      final artists = <Artist>[];
      final playlists = <Playlist>[];

      for (final result in results) {
        if (result is yt.SearchVideo) {
          final cached = _songCache[result.id.value];
          if (cached != null) {
            songs.add(cached);
            continue;
          }
          final song = _mapToSong(
            id: result.id.value,
            rawTitle: result.title,
            rawArtist: result.author,
            duration: _parseDuration(result.duration),
          );
          _songCache[song.id] = song;
          songs.add(song);
        } else if (result is yt.SearchPlaylist) {
          playlists.add(Playlist(
            id: result.id.value,
            title: result.title,
            description: 'YouTube Playlist',
            cover: Artwork(result.thumbnails.isNotEmpty ? result.thumbnails.first.url.toString() : ''),
            owner: 'YouTube',
            songIds: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        } else if (result is yt.SearchChannel) {
          artists.add(Artist(
            id: result.id.value,
            name: result.name,
            image: Artwork(result.thumbnails.isNotEmpty ? result.thumbnails.first.url.toString() : ''),
            subscriberCount: 0,
            description: result.description,
            genres: const [],
          ));
        }
      }

      return SearchResult(
        songs: songs,
        albums: albums,
        artists: artists,
        playlists: playlists,
        topResult: songs.isNotEmpty ? songs.first : null,
      );
    } catch (e, stack) {
      DALogger.error('YouTubeMusicAdapter: Search failed for "$query"', e, stack);
      throw SourceException('Search request failed: $e', e.toString());
    }
  }

  @override
  Future<HomeFeed> getHome() async {
    _checkInitialized();
    DALogger.info('YouTubeMusicAdapter: Fetching Home Feed (songs, albums, playlists)...');

    try {
      final songResults = await _ytClient.search.searchContent('trending songs', filter: yt.TypeFilters.video);
      final songs = songResults.whereType<yt.SearchVideo>().map((v) {
        final song = Song(
          id: v.id.value,
          title: v.title,
          artistId: v.author,
          albumId: 'yt_album_unknown',
          duration: DurationValue(_parseDuration(v.duration)),
          thumbnail: Artwork(v.thumbnails.isNotEmpty ? v.thumbnails.first.url.toString() : ''),
          artwork: Artwork(v.thumbnails.isNotEmpty ? v.thumbnails.last.url.toString() : ''),
          sourceId: id,
        );
        _songCache[song.id] = song;
        return song;
      }).take(6).toList();

      final albumResults = await _ytClient.search.searchContent('music albums', filter: yt.TypeFilters.playlist);
      final albums = albumResults.whereType<yt.SearchPlaylist>().map((p) => Album(
        id: p.id.value,
        title: p.title,
        artistId: 'Various Artists',
        cover: Artwork(p.thumbnails.isNotEmpty ? p.thumbnails.first.url.toString() : ''),
        year: 2026,
        trackCount: p.videoCount,
        duration: DurationValue(const Duration(minutes: 40)),
      )).take(6).toList();

      final playlistResults = await _ytClient.search.searchContent('music playlists', filter: yt.TypeFilters.playlist);
      final playlists = playlistResults.whereType<yt.SearchPlaylist>().map((p) => Playlist(
        id: p.id.value,
        title: p.title,
        description: 'YouTube Playlist',
        cover: Artwork(p.thumbnails.isNotEmpty ? p.thumbnails.first.url.toString() : ''),
        owner: 'YouTube',
        songIds: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).take(6).toList();

      return HomeFeed(
        sections: [
          HomeFeedSection(
            title: 'Recommended for You',
            type: 'recommended',
            items: songs,
          ),
          HomeFeedSection(
            title: 'Trending Albums',
            type: 'albums',
            items: albums,
          ),
          HomeFeedSection(
            title: 'Featured Playlists',
            type: 'playlists',
            items: playlists,
          ),
        ],
      );
    } catch (e, stack) {
      DALogger.error('YouTubeMusicAdapter: Failed to load Home Feed', e, stack);
      throw SourceException('Failed to load Home Feed: $e', e.toString());
    }
  }

  @override
  Future<Album> getAlbum(String id) async {
    _checkInitialized();
    DALogger.info('YouTubeMusicAdapter: Loading metadata for Album ID: "$id"');

    try {
      final details = await _fetchPlaylistDetails(id);
      
      for (final song in details.songs) {
        _songCache[song.id] = song;
      }

      Duration totalDuration = Duration.zero;
      for (final s in details.songs) {
        totalDuration += s.duration.value;
      }

      int year = DateTime.now().year;
      final regex = RegExp(r'\b(19\d\d|20\d\d)\b');
      final match = regex.firstMatch(details.playlist.description) ?? regex.firstMatch(details.playlist.owner);
      if (match != null) {
        year = int.parse(match.group(0)!);
      }

      return Album(
        id: details.playlist.id,
        title: details.playlist.title,
        artistId: details.playlist.owner,
        cover: details.playlist.cover,
        year: year,
        trackCount: details.songs.length,
        duration: DurationValue(totalDuration),
      );
    } catch (e) {
      DALogger.warning('YouTubeMusicAdapter: InnerTube browse failed for Album ID: "$id". Trying fallback. Error: $e');
      try {
        return await _getAlbumFallback(id);
      } catch (fallbackErr, fallbackStack) {
        DALogger.error('YouTubeMusicAdapter: Fallback failed to retrieve album metadata for ID: "$id"', fallbackErr, fallbackStack);
        throw SourceException('Failed to retrieve album metadata: $fallbackErr', fallbackErr.toString());
      }
    }
  }

  int _parseSubscriberCount(String? text) {
    if (text == null) return 0;
    final cleaned = text.toUpperCase().replaceAll(RegExp(r'[^0-9.KMB]'), '');
    if (cleaned.isEmpty) return 0;

    try {
      double value;
      if (cleaned.endsWith('M')) {
        value = double.parse(cleaned.substring(0, cleaned.length - 1)) * 1000000;
      } else if (cleaned.endsWith('K')) {
        value = double.parse(cleaned.substring(0, cleaned.length - 1)) * 1000;
      } else if (cleaned.endsWith('B')) {
        value = double.parse(cleaned.substring(0, cleaned.length - 1)) * 1000000000;
      } else {
        value = double.parse(cleaned);
      }
      return value.toInt();
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<Artist> getArtist(String id) async {
    _checkInitialized();
    DALogger.info('YouTubeMusicAdapter: Loading Channel details and shelves for Artist ID: "$id"');

    try {
      final client = HttpClient();
      const apiKey = 'AIzaSyAOghZGza2MQSZkY_zfZ370N-PUdXEo8AI';
      final url = Uri.parse('https://music.youtube.com/youtubei/v1/browse?key=$apiKey');
      
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
      
      final payload = {
        'browseId': id,
        'context': {
          'client': {
            'clientName': 'WEB_REMIX',
            'clientVersion': '1.20260707.01.00',
            'hl': 'en',
            'gl': 'US',
          }
        }
      };

      request.write(json.encode(payload));
      final responseObj = await request.close();
      final rawBody = await responseObj.transform(utf8.decoder).join();
      final response = json.decode(rawBody) as Map<String, dynamic>;

      if (response['error'] != null) {
        throw SourceException('InnerTube browse error: ${json.encode(response['error'])}');
      }

      String title = 'Unknown Artist';
      String subCountText = '';
      String? coverUrl;
      String description = '';

      if (response['header'] != null) {
        final header = response['header'];
        final headerRenderer = header['musicVisualHeaderRenderer'] ?? header['musicHeaderRenderer'] ?? header['musicImmersiveHeaderRenderer'];
        if (headerRenderer != null) {
          title = headerRenderer['title']?['runs']?[0]?['text'] ?? 'Unknown Artist';
          subCountText = headerRenderer['subscriptionButton']?['subscribeButtonRenderer']?['subscriberCountWithText']?['runs']?[0]?['text'] ?? 
                         headerRenderer['subscriptionButton']?['subscribeButtonRenderer']?['subscriberCountText']?['runs']?[0]?['text'] ??
                         headerRenderer['subtitle']?['runs']?[0]?['text'] ?? '';
          
          final thumbs = headerRenderer['foregroundThumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List? ??
                         headerRenderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
          if (thumbs != null && thumbs.isNotEmpty) {
            coverUrl = thumbs.last['url'] as String?;
          }
        }
      }

      final songs = <Song>[];
      final albums = <Album>[];
      final singles = <Album>[];
      final playlists = <Playlist>[];
      final related = <Artist>[];

      final contents = response['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] as List?;
      if (contents != null) {
        for (final section in contents) {
          final shelf = section['musicShelfRenderer'];
          final carousel = section['musicCarouselShelfRenderer'];
          final descShelf = section['musicDescriptionShelfRenderer'];

          if (shelf != null) {
            final sectionTitle = shelf['title']?['runs']?[0]?['text'] as String? ?? '';
            if (sectionTitle.toLowerCase() == 'top songs' || sectionTitle.toLowerCase() == 'songs') {
              final items = shelf['contents'] as List?;
              if (items != null) {
                for (final itemContainer in items) {
                  final item = itemContainer['musicResponsiveListItemRenderer'];
                  if (item == null) continue;

                  final trackTitle = item['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'] as String? ?? 'Unknown Title';
                  final videoId = item['playlistItemData']?['videoId'] as String? ??
                                  item['onTap']?['watchEndpoint']?['videoId'] as String?;
                  if (videoId == null) continue;

                  final artistRuns = item['flexColumns']?[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
                  final trackArtist = artistRuns != null && artistRuns.isNotEmpty 
                      ? artistRuns.map((r) => r['text']).join('') 
                      : title;



                  final cached = _songCache[videoId];
                  if (cached != null) {
                    songs.add(cached);
                    continue;
                  }
                  final durationRuns = item['fixedColumns']?[0]?['musicResponsiveListItemFixedColumnRenderer']?['text']?['runs'] as List?;
                  final durationStr = durationRuns != null && durationRuns.isNotEmpty ? durationRuns[0]['text'] as String : '';

                  final cleanAlbum = _extractAlbumNameFromFlexColumns(item) ?? 'Single';
                  final song = _mapToSong(
                    id: videoId,
                    rawTitle: trackTitle,
                    rawArtist: trackArtist,
                    duration: _parseDurationString(durationStr),
                    albumId: cleanAlbum,
                  );
                  songs.add(song);
                  _songCache[song.id] = song;
                }
              }
            }
          } else if (carousel != null) {
            final sectionTitle = carousel['header']?['musicCarouselShelfBasicHeaderRenderer']?['title']?['runs']?[0]?['text'] as String? ?? '';
            final items = carousel['contents'] as List?;
            if (items != null) {
              for (final itemContainer in items) {
                final item = itemContainer['musicTwoRowItemRenderer'];
                if (item == null) continue;

                final itemTitle = item['title']?['runs']?[0]?['text'] as String? ?? 'Unknown';
                final browseId = item['navigationEndpoint']?['browseEndpoint']?['browseId'] as String?;
                if (browseId == null) continue;

                final itemThumbs = item['thumbnailRenderer']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
                final thumbUrl = itemThumbs != null && itemThumbs.isNotEmpty ? itemThumbs.last['url'] as String : (coverUrl ?? '');

                final subtitle = item['subtitle']?['runs']?[0]?['text'] as String?;

                int year = DateTime.now().year;
                if (subtitle != null) {
                  final match = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(subtitle);
                  if (match != null) {
                    year = int.parse(match.group(0)!);
                  }
                }

                if (sectionTitle.toLowerCase() == 'albums') {
                  albums.add(Album(
                    id: browseId,
                    title: itemTitle,
                    artistId: title,
                    cover: Artwork(thumbUrl),
                    year: year,
                    trackCount: 10,
                    duration: DurationValue(const Duration(minutes: 40)),
                  ));
                } else if (sectionTitle.toLowerCase() == 'singles & eps' || sectionTitle.toLowerCase() == 'singles') {
                  singles.add(Album(
                    id: browseId,
                    title: itemTitle,
                    artistId: title,
                    cover: Artwork(thumbUrl),
                    year: year,
                    trackCount: 1,
                    duration: DurationValue(const Duration(minutes: 4)),
                  ));
                } else if (sectionTitle.toLowerCase().contains('playlists')) {
                  playlists.add(Playlist(
                    id: browseId,
                    title: itemTitle,
                    description: 'Playlist by $title',
                    cover: Artwork(thumbUrl),
                    owner: subtitle ?? title,
                    songIds: const [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ));
                } else if (sectionTitle.toLowerCase().contains('fans') || sectionTitle.toLowerCase().contains('like')) {
                  related.add(Artist(
                    id: browseId,
                    name: itemTitle,
                    image: Artwork(thumbUrl),
                    subscriberCount: 0,
                    description: 'Similar Artist',
                    genres: const [],
                  ));
                }
              }
            }
          } else if (descShelf != null) {
            final runs = descShelf['description']?['runs'] as List?;
            if (runs != null) {
              description = runs.map((r) => r['text']).join('');
            }
          }
        }
      }

      // Save into adapter local caches
      _artistSongs[id] = songs;
      _artistAlbums[id] = albums;
      _artistSingles[id] = singles;
      _artistPlaylists[id] = playlists;
      _artistRelated[id] = related;

      return Artist(
        id: id,
        name: title,
        image: Artwork(coverUrl ?? ''),
        subscriberCount: _parseSubscriberCount(subCountText),
        description: description.isNotEmpty ? description : 'Official YouTube Channel catalog',
        genres: const [],
      );
    } catch (e, stack) {
      DALogger.error('YouTubeMusicAdapter: Failed to retrieve artist details for ID: "$id"', e, stack);
      try {
        final channel = await _ytClient.channels.get(id);
        return Artist(
          id: channel.id.value,
          name: channel.title,
          image: Artwork(channel.logoUrl),
          subscriberCount: 0,
          description: 'Official YouTube Channel catalog',
          genres: const [],
        );
      } catch (fallbackErr, fallbackStack) {
        DALogger.error('YouTubeMusicAdapter: Fallback failed to retrieve artist for ID: "$id"', fallbackErr, fallbackStack);
        throw SourceException('Failed to retrieve artist: $fallbackErr', fallbackErr.toString());
      }
    }
  }

  @override
  Future<Playlist> getPlaylist(String id) async {
    _checkInitialized();
    DALogger.info('YouTubeMusicAdapter: Loading playlist tracks for ID: "$id"');

    try {
      final details = await _fetchPlaylistDetails(id);
      
      for (final song in details.songs) {
        _songCache[song.id] = song;
      }

      return details.playlist;
    } catch (e) {
      DALogger.warning('YouTubeMusicAdapter: InnerTube browse failed for Playlist ID: "$id". Trying fallback. Error: $e');
      try {
        return await _getPlaylistFallback(id);
      } catch (fallbackErr, fallbackStack) {
        DALogger.error('YouTubeMusicAdapter: Fallback failed to retrieve playlist details for ID: "$id"', fallbackErr, fallbackStack);
        throw SourceException('Failed to retrieve playlist: $fallbackErr', fallbackErr.toString());
      }
    }
  }

  @override
  Future<Song> getSong(String id) async {
    _checkInitialized();
    final cached = _songCache[id];
    if (cached != null) {
      DALogger.info('YouTubeMusicAdapter: Reusing cached video metadata for Song ID: "$id"');
      return cached;
    }

    DALogger.info('YouTubeMusicAdapter: Loading video metadata for Song ID: "$id"');

    try {
      final video = await _ytClient.videos.get(id);
      final song = _mapToSong(
        id: video.id.value,
        rawTitle: video.title,
        rawArtist: video.author,
        duration: video.duration ?? const Duration(minutes: 3),
      );
      _songCache[id] = song;
      return song;
    } catch (e, stack) {
      DALogger.error('YouTubeMusicAdapter: Failed to retrieve video metadata for ID: "$id"', e, stack);
      throw SourceException('Failed to retrieve song metadata: $e', e.toString());
    }
  }

  @override
  Future<Lyrics> getLyrics(String id) async {
    _checkInitialized();
    DALogger.info('YouTubeMusicAdapter: Resolving captions for Lyrics ID: "$id"');

    try {
      final manifest = await _ytClient.videos.closedCaptions.getManifest(id);
      if (manifest.tracks.isNotEmpty) {
        final track = manifest.tracks.first;
        final captions = await _ytClient.videos.closedCaptions.get(track);
        final lines = captions.captions.map((c) => c.text).join('\n');
        return Lyrics(
          songId: id,
          plainLyrics: lines,
          syncedLyrics: null,
          language: track.language.code,
          provider: 'youtube_captions',
        );
      }
    } catch (_) {
      // Return plain captions description if captions resolution fails
    }

    return Lyrics(
      songId: id,
      plainLyrics: 'Lyrics are unavailable for this song.',
      syncedLyrics: null,
      language: 'en',
      provider: 'musixmatch_fallback',
    );
  }

  @override
  Future<List<Song>> getRelated(String id) async {
    _checkInitialized();
    DALogger.info('YouTubeMusicAdapter: Loading related tracks for ID: "$id"');

    try {
      final video = await _ytClient.videos.get(id);
      final related = await _ytClient.videos.getRelatedVideos(video);
      if (related != null) {
        return related.map((v) {
          final song = Song(
            id: v.id.value,
            title: v.title,
            artistId: v.author,
            albumId: 'yt_album_unknown',
            duration: DurationValue(v.duration ?? const Duration(minutes: 3)),
            thumbnail: Artwork(v.thumbnails.lowResUrl),
            artwork: Artwork(v.thumbnails.highResUrl),
            sourceId: this.id,
          );
          _songCache[song.id] = song;
          return song;
        }).toList();
      }
    } catch (e, stack) {
      DALogger.error('YouTubeMusicAdapter: Failed to retrieve related videos for ID: "$id"', e, stack);
    }
    return const [];
  }

  @override
  Future<List<Song>> getRecommendations(String id) => getRelated(id);

  String _cleanQuery(String artist, String title) {
    final cleanArtist = artist.replaceAll(' - Topic', '').replaceAll('VEVO', '').trim();
    final cleanTitle = title.replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '').trim();
    return '$cleanArtist $cleanTitle'.trim();
  }

  yt.SearchVideo? rankFallbackCandidates({
    required List<yt.SearchVideo> candidates,
    required String originalId,
    required String originalTitle,
    required String originalArtist,
    required String originalAlbum,
    required Duration originalDuration,
  }) {
    if (candidates.isEmpty) return null;

    final scored = <({yt.SearchVideo video, int score, String reasons})>[];

    final normOrigTitle = originalTitle.toLowerCase().replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '').trim();
    final normOrigArtist = originalArtist.toLowerCase().replaceAll(' - topic', '').replaceAll('vevo', '').trim();
    
    final origArtistParts = normOrigArtist.split(RegExp(r'[,&]|\b(feat|ft|and)\b')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final bool origIsRemix = normOrigTitle.contains('remix');

    for (final c in candidates) {
      if (c.id.value == originalId) continue;

      int score = 0;
      final reasons = <String>[];

      // 1. Artist Matching
      final normAuthor = c.author.toLowerCase().replaceAll(' - topic', '').replaceAll('vevo', '').trim();
      final candArtistParts = normAuthor.split(RegExp(r'[,&]|\b(feat|ft|and)\b')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      
      bool exactArtist = false;
      bool partialArtist = false;

      for (final op in origArtistParts) {
        for (final cp in candArtistParts) {
          if (op == cp) {
            exactArtist = true;
            break;
          }
          if (op.contains(cp) || cp.contains(op)) {
            partialArtist = true;
          }
        }
        if (exactArtist) break;
      }

      if (exactArtist) {
        score += 2000;
        reasons.add('Exact artist match (+2000)');
      } else if (partialArtist) {
        score += 1000;
        reasons.add('Partial artist match (+1000)');
      } else if (c.title.toLowerCase().contains(normOrigArtist)) {
        score += 500;
        reasons.add('Artist in title match (+500)');
      } else {
        score -= 5000;
        reasons.add('Different artist penalty (-5000)');
      }

      // Reject completely if no artist overlap is present to prevent wrong artist substitutions
      if (!exactArtist && !partialArtist && !c.title.toLowerCase().contains(normOrigArtist)) {
        continue;
      }

      // 2. Song Title Match
      final cleanCandTitle = c.title.toLowerCase().replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '').trim();
      final normCandTitle = cleanCandTitle.replaceAll('&', 'and').replaceAll(RegExp(r'[^a-z0-9]'), '');
      final normOrigTitleClean = normOrigTitle.replaceAll('&', 'and').replaceAll(RegExp(r'[^a-z0-9]'), '');

      if (normCandTitle == normOrigTitleClean) {
        score += 2000;
        reasons.add('Exact title match (+2000)');
      } else if (normCandTitle.contains(normOrigTitleClean) || normOrigTitleClean.contains(normCandTitle)) {
        score += 1000;
        reasons.add('Partial title match (+1000)');
      } else {
        continue; // Title completely different
      }

      // 3. Remix/Cover/Karaoke/Instrumental penalties
      final bool candIsRemix = cleanCandTitle.contains('remix');
      if (candIsRemix && !origIsRemix) {
        score -= 3000;
        reasons.add('Unofficial Remix penalty (-3000)');
      }
      
      final bool candIsCover = cleanCandTitle.contains('cover') || cleanCandTitle.contains('tribute');
      if (candIsCover && !normOrigTitle.contains('cover')) {
        score -= 3000;
        reasons.add('Cover version penalty (-3000)');
      }

      final bool candIsKaraoke = cleanCandTitle.contains('karaoke') || cleanCandTitle.contains('instrumental');
      if (candIsKaraoke && !normOrigTitle.contains('karaoke') && !normOrigTitle.contains('instrumental')) {
        score -= 3000;
        reasons.add('Karaoke/Instrumental penalty (-3000)');
      }

      final bool candIsLyricsOrFan = cleanCandTitle.contains('lyrics') || cleanCandTitle.contains('lyric video') || cleanCandTitle.contains('fan-made') || cleanCandTitle.contains('unofficial');
      if (candIsLyricsOrFan) {
        score -= 1000;
        reasons.add('Unofficial/Lyrics video penalty (-1000)');
      }

      // 4. Album Match (if available)
      if (originalAlbum != 'yt_album_unknown' && originalAlbum.isNotEmpty) {
        final normAlbum = originalAlbum.toLowerCase().trim();
        final candidateText = '${c.title} ${c.author}'.toLowerCase();
        if (candidateText.contains(normAlbum)) {
          score += 800;
          reasons.add('Album match (+800)');
        }
      }

      // 5. Strict Duration Matching
      final diff = _parseDuration(c.duration).inSeconds - originalDuration.inSeconds;
      if (diff.abs() <= 3) {
        score += 1200;
        reasons.add('Duration matches within ±3s (+1200)');
      } else if (diff.abs() <= 8) {
        score += 600;
        reasons.add('Duration matches within ±8s (+600)');
      } else if (diff.abs() > 30) {
        score -= 1500;
        reasons.add('Duration mismatch >30s penalty (-1500)');
      } else if (diff.abs() > 15) {
        score -= 800;
        reasons.add('Duration mismatch >15s penalty (-800)');
      }

      // 6. Official upload checks
      if (c.author.endsWith(' - Topic')) {
        score += 1500;
        reasons.add('Official YT Music Topic channel (+1500)');
      } else if (c.author.toLowerCase().contains('official') || c.title.toLowerCase().contains('official')) {
        score += 500;
        reasons.add('Official artist/video upload (+500)');
      }

      scored.add((video: c, score: score, reasons: reasons.join(', ')));
    }

    if (scored.isEmpty) return null;

    scored.sort((a, b) => b.score.compareTo(a.score));

    DALogger.info('=== FALLBACK CANDIDATE RANKING FOR "$originalTitle" by "$originalArtist" ===');
    for (final s in scored) {
      DALogger.info('  - Candidate [${s.video.id.value}] "${s.video.title}" by "${s.video.author}": Score = ${s.score} (Reasons: ${s.reasons})');
    }
    DALogger.info('  -> Selected candidate: [${scored.first.video.id.value}] "${scored.first.video.title}" with score ${scored.first.score}');
    DALogger.info('========================================================================');

    if (scored.first.score < 400) {
      DALogger.info('YouTubeMusicAdapter: Selected fallback candidate has low score (${scored.first.score}). Aborting fallback to prevent wrong song playback.');
      return null;
    }

    return scored.first.video;
  }

  @override
  Future<AudioStream> getAudioStream(String id) async {
    _checkInitialized();
    DALogger.info('YouTubeMusicAdapter: Resolving audio stream for ID: "$id"');

    if (id.startsWith('mock_') || id == '1' || id == '2' || id == '3') {
      return AudioStream(
        id: id,
        providerId: this.id,
        streamUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        mimeType: 'audio/mp3',
        bitrate: 128000,
        duration: const Duration(minutes: 3),
        expiresAt: DateTime.now().add(const Duration(hours: 4)),
        headers: const {},
        quality: 'highest',
        codec: 'mp3',
        isLive: false,
        isCached: false,
      );
    }

    // 1. Determine if this is a Topic track (official audio track) and store metadata
    String? fallbackQuery;
    String? originalTitle;
    String? originalArtist;
    String? originalAlbum;
    Duration originalDuration = const Duration(minutes: 3);

    final cached = _songCache[id];
    if (cached != null) {
      originalTitle = cached.title;
      originalArtist = cached.artistId;
      originalAlbum = cached.albumId;
      originalDuration = cached.duration.value;
      fallbackQuery = _cleanQuery(originalArtist, originalTitle);
    } else {
      try {
        final video = await _ytClient.videos.get(id);
        originalTitle = video.title;
        originalArtist = video.author;
        originalAlbum = 'yt_album_unknown';
        originalDuration = video.duration ?? const Duration(minutes: 3);
        fallbackQuery = _cleanQuery(video.author, video.title);
      } catch (_) {}
    }

    // 2. Direct resolution (Always attempt first to play original ID)
    try {
      final manifest = await _ytClient.videos.streamsClient.getManifest(
        id,
        ytClients: [yt.YoutubeApiClient.androidVr],
      ).timeout(const Duration(milliseconds: 15000));
      
      var audioStreams = manifest.audioOnly.where((s) => s.container.name == 'mp4').toList();
      if (audioStreams.isEmpty) {
        audioStreams = manifest.audioOnly.toList();
      }
      final audioStreamInfo = audioStreams.withHighestBitrate();
      final streamUrl = audioStreamInfo.url.toString();

      final isPlayable = await _isStreamPlayable(streamUrl);
      if (!isPlayable) {
        throw Exception('Stream URL returned 403 Forbidden or is unplayable.');
      }

      return AudioStream(
        id: id,
        providerId: this.id,
        streamUrl: streamUrl,
        mimeType: 'audio/${audioStreamInfo.codec.subtype}',
        bitrate: audioStreamInfo.bitrate.bitsPerSecond,
        duration: originalDuration,
        expiresAt: DateTime.now().add(const Duration(hours: 4)),
        headers: const {},
        quality: 'highest',
        codec: audioStreamInfo.codec.subtype,
        isLive: false,
        isCached: false,
      );
    } catch (e) {
      DALogger.info('YouTubeMusicAdapter: Direct stream resolution failed for ID "$id": $e. Attempting search fallback as last resort...');
      
      if (fallbackQuery != null) {
        try {
          DALogger.info('YouTubeMusicAdapter: Searching fallback for: "$fallbackQuery"');
          final searchResults = await _ytClient.search.searchContent(fallbackQuery);
          final candidates = searchResults.whereType<yt.SearchVideo>().toList();
          final fallbackVideo = rankFallbackCandidates(
            candidates: candidates,
            originalId: id,
            originalTitle: originalTitle ?? '',
            originalArtist: originalArtist ?? '',
            originalAlbum: originalAlbum ?? 'yt_album_unknown',
            originalDuration: originalDuration,
          );

          if (fallbackVideo != null) {
            final fallbackId = fallbackVideo.id.value;
            final manifest = await _ytClient.videos.streamsClient.getManifest(
              fallbackId,
              ytClients: [yt.YoutubeApiClient.androidVr],
            ).timeout(const Duration(milliseconds: 15000));

            var audioStreams = manifest.audioOnly.where((s) => s.container.name == 'mp4').toList();
            if (audioStreams.isEmpty) {
              audioStreams = manifest.audioOnly.toList();
            }
            final audioStreamInfo = audioStreams.withHighestBitrate();

            DALogger.info('YouTubeMusicAdapter: Resolved fallback stream successfully for ID "$id" via "$fallbackId"');
            return AudioStream(
              id: id, // Must return the original ID
              providerId: this.id,
              streamUrl: audioStreamInfo.url.toString(),
              mimeType: 'audio/${audioStreamInfo.codec.subtype}',
              bitrate: audioStreamInfo.bitrate.bitsPerSecond,
              duration: originalDuration,
              expiresAt: DateTime.now().add(const Duration(hours: 4)),
              headers: const {},
              quality: 'highest',
              codec: audioStreamInfo.codec.subtype,
              isLive: false,
              isCached: false,
            );
          }
        } catch (err, stack) {
          DALogger.error('YouTubeMusicAdapter: Fallback resolution failed for query "$fallbackQuery"', err, stack);
        }
      }
      
      throw SourceException('Failed to resolve audio stream for ID "$id": $e', e.toString());
    }
  }

  Future<bool> _isStreamPlayable(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 2));
      request.headers.set('Range', 'bytes=0-0');
      final response = await request.close().timeout(const Duration(seconds: 2));
      return response.statusCode == 200 || response.statusCode == 206;
    } catch (_) {}
    return false;
  }

  Future<({Playlist playlist, List<Song> songs})> _fetchPlaylistDetails(String id) async {
    final client = HttpClient();
    try {
      const apiKey = 'AIzaSyAOghZGza2MQSZkY_zfZ370N-PUdXEo8AI';
      final url = Uri.parse('https://music.youtube.com/youtubei/v1/browse?key=$apiKey');
      
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
      
      final payload = {
        'browseId': id.startsWith('PL') || id.startsWith('RD') ? 'VL$id' : id,
        'context': {
          'client': {
            'clientName': 'WEB_REMIX',
            'clientVersion': '1.20260707.01.00',
            'hl': 'en',
            'gl': 'US',
          }
        }
      };

      request.write(json.encode(payload));
      final response = await request.close();
      final rawBody = await response.transform(utf8.decoder).join();
      final body = json.decode(rawBody) as Map<String, dynamic>;

      if (body['error'] != null) {
        throw SourceException('InnerTube browse error: ${json.encode(body['error'])}');
      }

      final contents = body['contents'] as Map<String, dynamic>?;
      if (contents == null) {
        throw const SourceException('Invalid response: contents is null');
      }

      final twoCol = contents['twoColumnBrowseResultsRenderer'] as Map<String, dynamic>?;
      if (twoCol == null) {
        throw const SourceException('Invalid response: twoColumnBrowseResultsRenderer is null');
      }

      String title = '';
      String author = '';
      String description = '';
      String coverUrl = '';

      final tabs = twoCol['tabs'] as List?;
      if (tabs != null && tabs.isNotEmpty) {
        final tabContent = tabs[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] as List?;
        if (tabContent != null && tabContent.isNotEmpty) {
          final headerRenderer = tabContent[0]['musicResponsiveHeaderRenderer'] as Map<String, dynamic>?;
          if (headerRenderer != null) {
            title = headerRenderer['title']?['runs']?[0]?['text'] ?? '';
            final subtitleRuns = headerRenderer['subtitle']?['runs'] as List?;
            if (subtitleRuns != null) {
              author = subtitleRuns.map((r) => r['text']).join('');
            }
            final descRenderer = headerRenderer['description']?['musicDescriptionShelfRenderer'] as Map<String, dynamic>?;
            if (descRenderer != null) {
              final runs = descRenderer['description']?['runs'] as List?;
              if (runs != null) {
                description = runs.map((r) => r['text']).join('');
              }
            }
            final thumbList = headerRenderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
            if (thumbList != null && thumbList.isNotEmpty) {
              coverUrl = thumbList.last['url'] ?? '';
            }
          }
        }
      }

      final secondaryList = twoCol['secondaryContents']?['sectionListRenderer']?['contents'] as List?;
      List? trackItems;
      if (secondaryList != null && secondaryList.isNotEmpty) {
        final shelf = secondaryList[0]['musicPlaylistShelfRenderer'] ?? secondaryList[0]['musicShelfRenderer'];
        trackItems = shelf?['contents'] as List?;
      }
      
      final songs = <Song>[];
      if (trackItems != null) {
        for (final trackItem in trackItems) {
          final item = trackItem['musicResponsiveListItemRenderer'] as Map<String, dynamic>?;
          if (item == null) continue;

          final videoId = item['playlistItemData']?['videoId'] as String? ??
              item['onTap']?['watchEndpoint']?['videoId'] as String?;
          if (videoId == null) continue;

          final titleRuns = item['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
          final trackTitle = titleRuns != null && titleRuns.isNotEmpty ? titleRuns[0]['text'] as String : 'Unknown Track';

          final artistRuns = item['flexColumns']?[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
          String trackArtist = artistRuns != null && artistRuns.isNotEmpty ? artistRuns.map((r) => r['text']).join('') : '';
          if (trackArtist.trim().isEmpty || trackArtist.toLowerCase() == 'unknown artist') {
            // Attempt recovery from parent author subtitle
            if (author.isNotEmpty) {
              final parts = author.split(' • ');
              String resolved = '';
              for (final part in parts) {
                final p = part.trim();
                if (p.isEmpty ||
                    p.toLowerCase() == 'album' ||
                    p.toLowerCase() == 'playlist' ||
                    p.toLowerCase() == 'ep' ||
                    p.toLowerCase() == 'single' ||
                    RegExp(r'^\d+$').hasMatch(p) ||
                    p.contains('songs') ||
                    p.contains('minutes')) {
                  continue;
                }
                resolved = p;
                break;
              }
              trackArtist = resolved.isNotEmpty ? resolved : parts.first.trim();
            } else {
              trackArtist = 'Unknown Artist';
            }
          }



          final durationRuns = item['fixedColumns']?[0]?['musicResponsiveListItemFixedColumnRenderer']?['text']?['runs'] as List?;
          final durationStr = durationRuns != null && durationRuns.isNotEmpty ? durationRuns[0]['text'] as String : '';
          
          final itemThumbs = item['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
          final thumbUrl = itemThumbs != null && itemThumbs.isNotEmpty ? itemThumbs[0]['url'] as String : coverUrl;

          // ignore: avoid_print
          print('Original Provider Track:');
          // ignore: avoid_print
          print('  Title: $trackTitle');
          // ignore: avoid_print
          print('  Track ID: $videoId');
          // ignore: avoid_print
          print('  Provider ID: youtube_music');
          // ignore: avoid_print
          print('  Source ID: youtube_music');
          // ignore: avoid_print
          print('  Duration: $durationStr');
          // ignore: avoid_print
          print('  Artwork: $thumbUrl');

          final cached = _songCache[videoId];
          if (cached != null) {
            songs.add(cached);
            continue;
          }
          final String cleanAlbum;
          if (id.startsWith('MPREb_') || id.startsWith('OLAK5uy_')) {
            cleanAlbum = title.isNotEmpty ? title : 'Single';
          } else {
            cleanAlbum = _extractAlbumNameFromFlexColumns(item) ?? 'Single';
          }

          final song = _mapToSong(
            id: videoId,
            rawTitle: trackTitle,
            rawArtist: trackArtist,
            duration: _parseDurationString(durationStr),
            albumId: cleanAlbum,
          );
          songs.add(song);
          _songCache[song.id] = song;
        }
      }

      String cleanOwner = '';
      if (author.isNotEmpty) {
        final parts = author.split(' • ');
        for (final part in parts) {
          final p = part.trim();
          if (p.isEmpty ||
              p.toLowerCase() == 'album' ||
              p.toLowerCase() == 'playlist' ||
              p.toLowerCase() == 'ep' ||
              p.toLowerCase() == 'single' ||
              RegExp(r'^\d+$').hasMatch(p) ||
              p.contains('songs') ||
              p.contains('minutes') ||
              p.contains('likes')) {
            continue;
          }
          cleanOwner = p;
          break;
        }
        if (cleanOwner.isEmpty) {
          cleanOwner = parts.first.trim();
        }
      }
      if (cleanOwner.isEmpty || cleanOwner.toLowerCase() == 'album' || cleanOwner.toLowerCase() == 'playlist') {
        cleanOwner = 'Unknown Artist';
      }

      final playlistObj = Playlist(
        id: id,
        title: title,
        description: description,
        cover: Artwork(coverUrl),
        owner: cleanOwner,
        songIds: songs.map((s) => s.id).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return (playlist: playlistObj, songs: songs);
    } finally {
      client.close();
    }
  }

  Duration _parseDurationString(String str) {
    if (str.isEmpty) return const Duration(minutes: 3);
    final parts = str.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts[1]) ?? 0;
      return Duration(minutes: m, seconds: s);
    } else if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = int.tryParse(parts[2]) ?? 0;
      return Duration(hours: h, minutes: m, seconds: s);
    }
    return const Duration(minutes: 3);
  }

  Future<Album> _getAlbumFallback(String id) async {
    final playlist = await _ytClient.playlists.get(id);
    final videos = await _ytClient.playlists.getVideos(playlist.id).toList();

    Duration totalDuration = Duration.zero;
    for (final v in videos) {
      totalDuration += v.duration ?? const Duration(minutes: 3);
    }

    int year = DateTime.now().year;
    final regex = RegExp(r'\b(19\d\d|20\d\d)\b');
    final match = regex.firstMatch(playlist.description);
    if (match != null) {
      year = int.parse(match.group(0)!);
    }

    final songsList = videos.map((v) {
      // ignore: avoid_print
      print('Original Provider Track (fallback):');
      // ignore: avoid_print
      print('  Title: ${v.title}');
      // ignore: avoid_print
      print('  Track ID: ${v.id.value}');
      // ignore: avoid_print
      print('  Provider ID: youtube_music');
      // ignore: avoid_print
      print('  Source ID: youtube_music');
      // ignore: avoid_print
      print('  Duration: ${v.duration}');
      // ignore: avoid_print
      print('  Artwork: ${v.thumbnails.highResUrl}');

      String trackArtist = v.author;
      if (trackArtist.trim().isEmpty || trackArtist.toLowerCase() == 'unknown artist') {
        trackArtist = playlist.author.isNotEmpty ? playlist.author : 'Unknown Artist';
      }
      return Song(
        id: v.id.value,
        title: v.title,
        artistId: trackArtist,
        albumId: playlist.title.isNotEmpty ? playlist.title : 'Single',
        duration: DurationValue(v.duration ?? const Duration(minutes: 3)),
        thumbnail: Artwork(v.thumbnails.lowResUrl),
        artwork: Artwork(v.thumbnails.highResUrl),
        sourceId: this.id,
      );
    }).toList();

    for (final song in songsList) {
      _songCache[song.id] = song;
    }

    return Album(
      id: playlist.id.value,
      title: playlist.title,
      artistId: playlist.author,
      cover: Artwork(playlist.thumbnails.highResUrl),
      year: year,
      trackCount: playlist.videoCount ?? videos.length,
      duration: DurationValue(totalDuration),
    );
  }

  Future<Playlist> _getPlaylistFallback(String id) async {
    final playlist = await _ytClient.playlists.get(id);
    final videos = await _ytClient.playlists.getVideos(playlist.id).toList();

    final songsList = videos.map((v) {
      // ignore: avoid_print
      print('Original Provider Track (fallback):');
      // ignore: avoid_print
      print('  Title: ${v.title}');
      // ignore: avoid_print
      print('  Track ID: ${v.id.value}');
      // ignore: avoid_print
      print('  Provider ID: youtube_music');
      // ignore: avoid_print
      print('  Source ID: youtube_music');
      // ignore: avoid_print
      print('  Duration: ${v.duration}');
      // ignore: avoid_print
      print('  Artwork: ${v.thumbnails.highResUrl}');

      final cached = _songCache[v.id.value];
      if (cached != null) {
        return cached;
      }
      String trackArtist = v.author;
      if (trackArtist.trim().isEmpty || trackArtist.toLowerCase() == 'unknown artist') {
        trackArtist = playlist.author.isNotEmpty ? playlist.author : 'Unknown Artist';
      }
      return _mapToSong(
        id: v.id.value,
        rawTitle: v.title,
        rawArtist: trackArtist,
        duration: v.duration ?? const Duration(minutes: 3),
        albumId: 'Single',
      );
    }).toList();

    for (final song in songsList) {
      _songCache[song.id] = song;
    }

    return Playlist(
      id: playlist.id.value,
      title: playlist.title,
      description: playlist.description,
      cover: Artwork(playlist.thumbnails.highResUrl),
      owner: playlist.author,
      songIds: videos.map((v) => v.id.value).toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  ({String title, String artist}) _cleanTitleAndArtist(String rawTitle, String rawArtist) {
    String title = rawTitle;
    String artist = rawArtist;

    // Remove common video suffixes
    title = title.replaceAll(RegExp(r'\s*\(?\s*Official\s*(?:Music\s*)?Video\s*\)?', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'\s*\[?\s*Official\s*(?:Music\s*)?Video\s*\]?', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'\s*\(?\s*Lyrics?\s*(?:Video)?\s*\)?', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'\s*\[?\s*Lyrics?\s*(?:Video)?\s*\]?', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'\s*\(?\s*Audio\s*\)?', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'\s*\[?\s*Audio\s*\]?', caseSensitive: false), '');
    title = title.trim();

    final splitMatch = RegExp(r'^(.+?)\s*-\s*(.+)$');
    final match = splitMatch.firstMatch(title);
    if (match != null) {
      artist = match.group(1)!.trim();
      title = match.group(2)!.trim();
    }

    // Clean artist if it contains VEVO or Topic suffixes
    artist = artist.replaceAll(RegExp(r'VEVO$', caseSensitive: false), '');
    artist = artist.replaceAll(RegExp(r'\s*-\s*Topic$', caseSensitive: false), '');
    artist = artist.trim();

    return (title: title, artist: artist);
  }

  Song _mapToSong({
    required String id,
    required String rawTitle,
    required String rawArtist,
    required Duration duration,
    String albumId = 'yt_album_unknown',
  }) {
    final cleaned = _cleanTitleAndArtist(rawTitle, rawArtist);
    return Song(
      id: id,
      title: cleaned.title,
      artistId: cleaned.artist,
      albumId: albumId,
      duration: DurationValue(duration),
      thumbnail: Artwork('https://i.ytimg.com/vi/$id/mqdefault.jpg'),
      artwork: Artwork('https://i.ytimg.com/vi/$id/hqdefault.jpg'),
      sourceId: this.id,
    );
  }

  String? _extractAlbumNameFromFlexColumns(Map<String, dynamic> item) {
    final flexColumns = item['flexColumns'] as List?;
    if (flexColumns == null) return null;
    for (final column in flexColumns) {
      final runs = column['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
      if (runs == null) continue;
      for (final run in runs) {
        final pageType = run['navigationEndpoint']?['browseEndpoint']?['browseEndpointContextSupportedConfigs']?['browseEndpointContextMusicConfig']?['pageType'] as String?;
        if (pageType == 'MUSIC_PAGE_TYPE_ALBUM') {
          final text = run['text'] as String?;
          if (text != null && text.isNotEmpty) {
            return text;
          }
        }
      }
    }
    return null;
  }
}
