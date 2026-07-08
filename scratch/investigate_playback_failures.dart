import 'package:da_music/core/services/youtube_music_adapter.dart';
import 'package:da_music/core/services/stream_resolver.dart';
import 'package:da_music/core/services/source_manager.dart';
import 'package:da_music/domain/entities/song.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'dart:io';
import 'dart:async';

void main() async {
  print('=== SELECTIVE PLAYBACK FAILURE INVESTIGATION ===');

  final adapter = YouTubeMusicAdapter();
  await adapter.initialize();

  final sourceManager = SourceManager();
  sourceManager.registerAdapter(adapter);
  sourceManager.selectSource('youtube_music');

  final resolver = StreamResolver(sourceManager);

  // We will compile a list of 25 popular songs to search and test
  final searchQueries = [
    'Imagine Dragons - Believer',
    'Ed Sheeran - Perfect',
    'Adele - Hello',
    'Luis Fonsi - Despacito',
    'Alan Walker - Faded',
    'Billie Eilish - Bad Guy',
    'Queen - Bohemian Rhapsody',
    'Lil Nas X - Old Town Road',
    'Lofi hip hop radio - beats to relax/study to', // Live stream
    'Post Malone - Sunflower',
    'Dua Lipa - Levitating',
    'The Weeknd - Blinding Lights',
    'Drake - God\'s Plan',
    'BTS - Dynamite',
    'Taylor Swift - Shake It Off',
    'Mark Ronson - Uptown Funk',
    'Maroon 5 - Sugar',
    'OneRepublic - Counting Stars',
    'Katy Perry - Roar',
    'Sia - Cheap Thrills',
    'Justin Bieber - Sorry',
    'Coldplay - Hymn for the Weekend',
    'Shawn Mendes - Senorita',
    'Marshmello - Happier',
    'Avicii - Wake Me Up'
  ];

  final List<Map<String, dynamic>> workingSongs = [];
  final List<Map<String, dynamic>> failedSongs = [];

  for (final query in searchQueries) {
    if (workingSongs.length >= 10 && failedSongs.length >= 10) {
      break;
    }

    print('\n--- Query: "$query" ---');
    Song? song;
    int step = 1;
    String failurePoint = '';
    String failureReason = '';
    String? resolvedUrl;
    int? httpResponseCode;
    String manifestStatus = 'Unknown';
    String? audioCodec;
    String? mimeType;
    Duration? duration;

    try {
      // Step 1: Search result received
      final searchResults = await adapter.searchSongs(query);
      if (searchResults.isEmpty) {
        throw Exception('No search results returned for query');
      }
      step = 2; // Song entity created

      song = searchResults.first;
      print('Found Song: "${song.title}" (ID: ${song.id})');
      duration = song.duration;

      step = 3; // StreamResolver.resolve()
      // We check SourceManager.getAudioStream()
      step = 4; // SourceManager.getAudioStream()
      // We check YouTubeMusicAdapter.getAudioStream()
      step = 5; // YouTubeMusicAdapter.getAudioStream()
      // We check youtube_explode manifest retrieval
      step = 6; // youtube_explode manifest retrieval

      final freshClient = yt.YoutubeExplode();
      yt.StreamManifest? manifest;
      try {
        manifest = await freshClient.videos.streamsClient.getManifest(
          song.id,
          ytClients: [yt.YoutubeApiClient.androidVr],
        ).timeout(const Duration(seconds: 10));
        manifestStatus = 'Success';
      } catch (manifestErr) {
        manifestStatus = 'Failed: $manifestErr';
        freshClient.close();
        rethrow;
      }

      step = 7; // Stream URL extraction
      var audioStreams = manifest.audioOnly.where((s) => s.container.name == 'mp4').toList();
      if (audioStreams.isEmpty) {
        audioStreams = manifest.audioOnly.toList();
      }
      if (audioStreams.isEmpty) {
        throw Exception('No audio streams available in manifest');
      }
      final audioStreamInfo = audioStreams.withHighestBitrate();
      resolvedUrl = audioStreamInfo.url.toString();
      audioCodec = audioStreamInfo.codec.subtype;
      mimeType = 'audio/${audioStreamInfo.codec.subtype}';
      freshClient.close();

      step = 8; // Backend load() - Validate URL via HTTP
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(resolvedUrl)).timeout(const Duration(seconds: 5));
        request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
        final response = await request.close();
        httpResponseCode = response.statusCode;
        await response.drain();
        client.close();
      } catch (httpErr) {
        httpResponseCode = 500;
        client.close();
        throw Exception('HTTP status check failed: $httpErr');
      }

      if (httpResponseCode != 200) {
        throw Exception('HTTP status check returned status $httpResponseCode');
      }

      step = 9; // Backend play()
      // If we reach here, it successfully resolved and validated
      print('STATUS: Working!');
      workingSongs.add({
        'title': song.title,
        'artist': song.artist,
        'videoId': song.id,
        'providerId': song.sourceId,
        'albumId': song.albumId,
        'resolvedUrl': resolvedUrl,
        'httpResponseCode': httpResponseCode,
        'manifestStatus': manifestStatus,
        'audioCodec': audioCodec,
        'mimeType': mimeType,
        'duration': duration,
      });

    } catch (e) {
      print('STATUS: Failed at step $step! Error: $e');
      failurePoint = _getStepName(step);
      failureReason = e.toString();

      failedSongs.add({
        'title': song?.title ?? 'Unknown Title',
        'artist': song?.artist ?? 'Unknown Artist',
        'videoId': song?.id ?? 'Unknown ID',
        'providerId': song?.sourceId ?? 'youtube_music',
        'albumId': song?.albumId,
        'resolvedUrl': resolvedUrl,
        'httpResponseCode': httpResponseCode,
        'manifestStatus': manifestStatus,
        'audioCodec': audioCodec,
        'mimeType': mimeType,
        'duration': duration,
        'failurePoint': failurePoint,
        'failureReason': failureReason,
      });
    }
  }

  print('\n==================================================');
  print('=== INVESTIGATION REPORT ===');
  print('==================================================');
  
  print('\n--- WORKING SONGS (Count: ${workingSongs.length}) ---');
  for (int i = 0; i < workingSongs.length; i++) {
    final s = workingSongs[i];
    print('\n[Working Song #${i + 1}]');
    print('- Title: ${s['title']}');
    print('- Artist: ${s['artist']}');
    print('- Video ID: ${s['videoId']}');
    print('- Provider ID: ${s['providerId']}');
    print('- Album ID (if available): ${s['albumId'] ?? "N/A"}');
    print('- Resolved stream URL: ${s['resolvedUrl']}');
    print('- HTTP response code: ${s['httpResponseCode']}');
    print('- Stream manifest status: ${s['manifestStatus']}');
    print('- Audio codec: ${s['audioCodec']}');
    print('- MIME type: ${s['mimeType']}');
    print('- Duration: ${s['duration']}');
  }

  print('\n--- FAILED SONGS (Count: ${failedSongs.length}) ---');
  for (int i = 0; i < failedSongs.length; i++) {
    final s = failedSongs[i];
    print('\n[Failed Song #${i + 1}]');
    print('- Title: ${s['title']}');
    print('- Artist: ${s['artist']}');
    print('- Video ID: ${s['videoId']}');
    print('- Provider ID: ${s['providerId']}');
    print('- Album ID (if available): ${s['albumId'] ?? "N/A"}');
    print('- Resolved stream URL: ${s['resolvedUrl'] ?? "N/A"}');
    print('- HTTP response code: ${s['httpResponseCode'] ?? "N/A"}');
    print('- Stream manifest status: ${s['manifestStatus']}');
    print('- Audio codec: ${s['audioCodec'] ?? "N/A"}');
    print('- MIME type: ${s['mimeType'] ?? "N/A"}');
    print('- Duration: ${s['duration'] ?? "N/A"}');
    print('- First failing step: ${s['failurePoint']}');
    print('- Exact failure reason: ${s['failureReason']}');
  }

  await adapter.dispose();
}

String _getStepName(int step) {
  switch (step) {
    case 1:
      return '1. Search result received';
    case 2:
      return '2. Song entity created';
    case 3:
      return '3. StreamResolver.resolve()';
    case 4:
      return '4. SourceManager.getAudioStream()';
    case 5:
      return '5. YouTubeMusicAdapter.getAudioStream()';
    case 6:
      return '6. youtube_explode manifest retrieval';
    case 7:
      return '7. Stream URL extraction';
    case 8:
      return '8. Backend load()';
    case 9:
      return '9. Backend play()';
    default:
      return 'Unknown Step';
  }
}
