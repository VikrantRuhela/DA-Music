import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:da_music/core/services/secure_credential_store.dart';
import 'package:da_music/core/services/youtube_music_account_service.dart';
import 'package:da_music/core/services/session_manager.dart';
import 'package:da_music/shared/models/music_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('=== STARTING YTM DIAGNOSTICS ===');
  final secureStore = SecureCredentialStore();
  final cookies = await secureStore.readCookies();

  if (cookies == null || cookies.isEmpty) {
    print('ERROR: No saved YTM cookies found in SecureCredentialStore. Please sign in first.');
    final reportFile = File('C:/Users/vikrantrajput/.gemini/antigravity/brain/9900dfc4-0314-4708-86a2-3ff29a1fd44d/scratch/diagnostic_proof_report.md');
    await reportFile.writeAsString('# Diagnostic Report: Error\n\nNo cookies found in SecureCredentialStore. User must log in first.');
    exit(1);
  }

  print('SUCCESS: Found saved YTM session cookies.');
  final sessionManager = SessionManager(secureStore);
  await sessionManager.restoreSession();

  final client = sessionManager.client;
  if (client == null) {
    print('ERROR: Authenticated client is null.');
    exit(1);
  }

  // Parse Cookie names
  final List<String> cookieNames = [];
  final Map<String, String> cookiesMap = {};
  for (final part in cookies.split(';')) {
    final idx = part.indexOf('=');
    if (idx == -1) continue;
    final name = part.substring(0, idx).trim();
    final value = part.substring(idx + 1).trim();
    cookieNames.add(name);
    cookiesMap[name] = value;
  }

  final bool hasLoginInfo = cookiesMap.containsKey('LOGIN_INFO');
  final bool hasSapisid = cookiesMap.containsKey('SAPISID');
  final bool hasApisid = cookiesMap.containsKey('APISID');
  final bool hasSid = cookiesMap.containsKey('SID');
  final bool hasHsid = cookiesMap.containsKey('HSID');
  final bool hasSsid = cookiesMap.containsKey('SSID');

  final List<Map<String, dynamic>> endpointsDiag = [];
  final List<String> homeFeedShelves = [];
  String homeLoggedIn = 'unknown';
  int likedSongsCount = 0;
  int myPlaylistsCount = 0;

  // Helper to test an endpoint
  Future<void> testEndpoint(String name, String browseId) async {
    try {
      final response = await client.post(
        Uri.parse('https://music.youtube.com/youtubei/v1/browse?key=${YouTubeMusicAccountService.apiKey}&prettyPrint=false'),
        body: jsonEncode({
          "context": {
            "client": {
              "clientName": "WEB_REMIX",
              "clientVersion": "1.20260304.03.00",
              "hl": "en",
              "gl": "US"
            }
          },
          "browseId": browseId
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Extract logged_in value
        String loggedInValue = 'unknown';
        final trackingParams = json['responseContext']?['serviceTrackingParams'] as List?;
        if (trackingParams != null) {
          for (final service in trackingParams) {
            final params = service['params'] as List?;
            if (params != null) {
              for (final p in params) {
                if (p['key'] == 'logged_in') {
                  loggedInValue = p['value'] as String? ?? 'unknown';
                }
              }
            }
          }
        }

        if (name == 'Home Feed') {
          homeLoggedIn = loggedInValue;
          // Extract shelf titles
          void findShelfTitles(dynamic node) {
            if (node is Map) {
              if (node.containsKey('musicCarouselShelfRenderer')) {
                final title = node['musicCarouselShelfRenderer']?['header']?['musicCarouselShelfBasicHeaderRenderer']?['title']?['runs']?[0]?['text'] as String?;
                if (title != null) homeFeedShelves.add(title);
              } else if (node.containsKey('musicShelfRenderer')) {
                final title = node['musicShelfRenderer']?['title']?['runs']?[0]?['text'] as String?;
                if (title != null) homeFeedShelves.add(title);
              }
              node.values.forEach(findShelfTitles);
            } else if (node is List) {
              node.forEach(findShelfTitles);
            }
          }
          findShelfTitles(json);
        }

        // Count items
        int itemsCount = 0;
        void countItems(dynamic node) {
          if (node is Map) {
            if (node.containsKey('musicResponsiveListItemRenderer') || node.containsKey('musicTwoRowItemRenderer')) {
              itemsCount++;
            }
            node.values.forEach(countItems);
          } else if (node is List) {
            node.forEach(countItems);
          }
        }
        countItems(json);

        if (name == 'Liked Songs') {
          likedSongsCount = itemsCount;
        } else if (name == 'Liked Playlists') {
          myPlaylistsCount = itemsCount;
        }

        endpointsDiag.add({
          'name': name,
          'browseId': browseId,
          'status': response.statusCode,
          'loggedIn': loggedInValue,
          'itemsFound': itemsCount,
        });
      } else {
        endpointsDiag.add({
          'name': name,
          'browseId': browseId,
          'status': response.statusCode,
          'loggedIn': 'N/A',
          'itemsFound': 0,
        });
      }
    } catch (e) {
      print('Error testing $name: $e');
      endpointsDiag.add({
        'name': name,
        'browseId': browseId,
        'status': 500,
        'loggedIn': 'error',
        'itemsFound': 0,
      });
    }
  }

  await testEndpoint('Home Feed', 'FEmusic_home');
  await testEndpoint('Liked Songs', 'FEmusic_liked_videos');
  await testEndpoint('Liked Playlists', 'FEmusic_liked_playlists');
  await testEndpoint('History', 'FEmusic_history');

  // Build the markdown report content
  final buffer = StringBuffer();
  buffer.writeln('# Live Session Authentication Diagnostic Report');
  buffer.writeln('\nGenerated on: ${DateTime.now().toLocal()}\n');

  buffer.writeln('## 1. Cookie Inventory');
  buffer.writeln('| Cookie Name | Status |');
  buffer.writeln('| :--- | :--- |');
  buffer.writeln('| **LOGIN_INFO** | ${hasLoginInfo ? "✅ Present" : "❌ Missing"} |');
  buffer.writeln('| **SAPISID** | ${hasSapisid ? "✅ Present" : "❌ Missing"} |');
  buffer.writeln('| **APISID** | ${hasApisid ? "✅ Present" : "❌ Missing"} |');
  buffer.writeln('| **SID** | ${hasSid ? "✅ Present" : "❌ Missing"} |');
  buffer.writeln('| **HSID** | ${hasHsid ? "✅ Present" : "❌ Missing"} |');
  buffer.writeln('| **SSID** | ${hasSsid ? "✅ Present" : "❌ Missing"} |');
  
  buffer.writeln('\n**Other cookies present:** ${cookieNames.where((c) => !['LOGIN_INFO','SAPISID','APISID','SID','HSID','SSID'].contains(c)).join(', ')}\n');

  buffer.writeln('## 2. Server Response Authentication State');
  buffer.writeln('| Request Name | browseId | HTTP Status | Server `logged_in` Value | Items/Shelves Returned |');
  buffer.writeln('| :--- | :--- | :--- | :--- | :--- |');
  for (final diag in endpointsDiag) {
    buffer.writeln('| ${diag['name']} | `${diag['browseId']}` | ${diag['status']} | **${diag['loggedIn']}** | ${diag['itemsFound']} |');
  }

  buffer.writeln('\n## 3. Account Personalization Verification');
  final isPersonalized = homeFeedShelves.any((s) => s.toLowerCase().contains('again') || s.toLowerCase().contains('mix') || s.toLowerCase().contains('for you') || s.toLowerCase().contains('favorites') || s.toLowerCase().contains('recently'));
  buffer.writeln('- **Home Feed Shelves Returned:**');
  if (homeFeedShelves.isEmpty) {
    buffer.writeln('  - *None*');
  } else {
    for (final shelf in homeFeedShelves) {
      buffer.writeln('  - $shelf');
    }
  }
  buffer.writeln('\n- **Home Feed Classification:** ${isPersonalized ? "✅ PERSONALIZED (Account-specific shelves found)" : "❌ GENERIC (Guest shelves only)"}');
  buffer.writeln('- **Liked Songs Status:** ${likedSongsCount > 0 ? "✅ Verified ($likedSongsCount items returned)" : "❌ Guest sign-in page returned" }');
  buffer.writeln('- **My Playlists Status:** ${myPlaylistsCount > 0 ? "✅ Verified ($myPlaylistsCount items returned)" : "❌ Guest sign-in page returned" }');

  buffer.writeln('\n## 4. Final Verdict');
  final bool allPassed = homeLoggedIn == '1' && isPersonalized && likedSongsCount > 0;
  if (allPassed) {
    buffer.writeln('> [!NOTE]\n> **VERDICT: SUCCESS**. The server is officially returning authenticated account responses (`logged_in = 1`) with personalized playlists and home feed shelves.');
  } else {
    buffer.writeln('> [!WARNING]\n> **VERDICT: FAILURE**. The request is still being processed as an unauthenticated guest session. Review cookie harvest scopes or headers.');
  }

  final reportFile = File('C:/Users/vikrantrajput/.gemini/antigravity/brain/9900dfc4-0314-4708-86a2-3ff29a1fd44d/scratch/diagnostic_proof_report.md');
  await reportFile.writeAsString(buffer.toString());
  print('=== DIAGNOSTICS COMPLETED ===');
  print('Report written to: ${reportFile.path}');
  exit(0);
}
