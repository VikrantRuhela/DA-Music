import 'dart:convert';
import 'package:da_music/core/services/secure_credential_store.dart';
import 'package:da_music/core/services/session_manager.dart';
import 'package:da_music/core/services/youtube_music_account_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Test official YouTube Music Library browse endpoints', () async {
    final sessionManager = SessionManager(SecureCredentialStore());
    await sessionManager.restoreSession();

    if (!sessionManager.isLoggedIn || sessionManager.client == null) {
      print('Not logged in, cannot perform authenticated browse test');
      return;
    }

    final client = sessionManager.client!;
    const apiKey = YouTubeMusicAccountService.apiKey;

    final candidates = [
      {'browseId': 'FEmusic_liked_playlists'},
      {'browseId': 'FEmusic_library_landing'},
      {'browseId': 'FEmusic_library_landing', 'params': '4gIaEglwbGF5bGlzdHM%3D'},
      {'browseId': 'FEmusic_library_corpus_playlists'},
      {'browseId': 'FEmusic_liked_albums'},
      {'browseId': 'FEmusic_library_corpus_albums'},
      {'browseId': 'FEmusic_library_corpus_track_artists'},
      {'browseId': 'FEmusic_library_corpus_artists'},
      {'browseId': 'FEmusic_liked_videos'},
      {'browseId': 'FEmusic_history'},
    ];

    print('\n================ YTM BROWSE ENDPOINTS TEST START ================');
    for (final candidate in candidates) {
      final browseId = candidate['browseId']!;
      final params = candidate['params'];

      final Map<String, dynamic> payload = {
        'context': {
          'client': {
            'clientName': 'WEB_REMIX',
            'clientVersion': '1.20260304.03.00',
            'hl': 'en',
            'gl': 'US'
          }
        },
        'browseId': browseId
      };
      if (params != null) {
        payload['params'] = params;
      }

      final res = await client.post(
        Uri.parse('https://music.youtube.com/youtubei/v1/browse?key=$apiKey&prettyPrint=false'),
        body: jsonEncode(payload),
      );

      print('Candidate: browseId="$browseId"${params != null ? ', params="$params"' : ''}');
      print('  -> Status: ${res.statusCode}');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final tabs = body['contents']?['singleColumnBrowseResultsRenderer']?['tabs'] ??
                     body['contents']?['twoColumnBrowseResultsRenderer']?['tabs'];
        print('  -> Response Size: ${res.body.length} bytes, tabs count: ${(tabs as List?)?.length}');
      } else {
        print('  -> Body: ${res.body}');
      }
      print('--------------------------------------------------');
    }
    print('================ YTM BROWSE ENDPOINTS TEST END ==================\n');
  });
}
