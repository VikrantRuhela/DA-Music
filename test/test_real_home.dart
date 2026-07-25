import 'dart:io';
import 'package:da_music/core/services/youtube_music_adapter.dart';
import 'package:da_music/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Fetch Real Home Feed Test', () async {
    print('=== REAL HOME FEED FETCH TEST ===');
    
    // Setup FallbackHttpOverrides just in case
    HttpOverrides.global = FallbackHttpOverrides();
    
    final adapter = YouTubeMusicAdapter();
    
    try {
      print('Initializing YouTubeMusicAdapter...');
      await adapter.initialize();
      
      print('Calling getHome()...');
      final homeFeed = await adapter.getHome().timeout(Duration(seconds: 15));
      
      print('SUCCESS!');
      print('Sections: ${homeFeed.sections.length}');
      for (final section in homeFeed.sections) {
        print('Section: "${section.title}" (type: ${section.type}), Items: ${section.items.length}');
      }
    } catch (e, st) {
      print('FAILED with error: $e');
      print(st);
      fail('Failed to fetch home feed: $e');
    } finally {
      await adapter.dispose();
    }
  });
}
