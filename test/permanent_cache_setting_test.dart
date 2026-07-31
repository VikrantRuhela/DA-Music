// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:da_tunes/core/services/playback_prefetch_manager.dart';
import 'package:da_tunes/core/services/stream_resolver.dart';
import 'package:da_tunes/core/services/local_stream_proxy.dart';
import 'package:da_tunes/shared/models/music_models.dart';

class MockStreamResolver implements StreamResolver {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLocalStreamProxy implements LocalStreamProxy {
  @override
  void manageCacheSize(Directory cacheDir) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlaybackPrefetchManager prefetchManager;
  late Directory tempDir;
  late Directory prefetchDir;
  late Directory cacheDir;

  setUp(() async {
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (methodCall) async {
      return Directory.systemTemp.path;
    });

    tempDir = await getTemporaryDirectory();
    prefetchDir = Directory(p.join(tempDir.path, 'da_tunes_prefetch'));
    cacheDir = Directory(p.join(tempDir.path, 'da_tunes_cache'));

    if (prefetchDir.existsSync()) prefetchDir.deleteSync(recursive: true);
    if (cacheDir.existsSync()) cacheDir.deleteSync(recursive: true);

    prefetchDir.createSync(recursive: true);
    cacheDir.createSync(recursive: true);

    prefetchManager = PlaybackPrefetchManager(
      MockStreamResolver(),
      MockLocalStreamProxy(),
    );
  });

  tearDown(() {
    if (prefetchDir.existsSync()) prefetchDir.deleteSync(recursive: true);
    if (cacheDir.existsSync()) cacheDir.deleteSync(recursive: true);
  });

  group('Permanent Cache Setting Tests', () {
    test('When permanent cache is ENABLED, promoteToCache moves prefetch file to da_tunes_cache', () async {
      const songId = 'test_song_1';
      final prefetchedFile = File(p.join(prefetchDir.path, '$songId.prefetch'))..writeAsStringSync('audio_data');
      final prefetchedArt = File(p.join(prefetchDir.path, '$songId.jpg'))..writeAsStringSync('art_data');

      prefetchManager.isPermanentCacheEnabled = true;
      await prefetchManager.promoteToCache(songId);

      final cachedFile = File(p.join(cacheDir.path, '$songId.mp3'));
      final cachedArt = File(p.join(cacheDir.path, '$songId.jpg'));

      expect(cachedFile.existsSync(), isTrue);
      expect(cachedArt.existsSync(), isTrue);
      expect(prefetchedFile.existsSync(), isFalse);
    });

    test('When permanent cache is DISABLED, promoteToCache skips promotion and leaves prefetch file intact', () async {
      const songId = 'test_song_2';
      final prefetchedFile = File(p.join(prefetchDir.path, '$songId.prefetch'))..writeAsStringSync('audio_data');
      final prefetchedArt = File(p.join(prefetchDir.path, '$songId.jpg'))..writeAsStringSync('art_data');

      prefetchManager.isPermanentCacheEnabled = false;
      await prefetchManager.promoteToCache(songId);

      final cachedFile = File(p.join(cacheDir.path, '$songId.mp3'));
      final cachedArt = File(p.join(cacheDir.path, '$songId.jpg'));

      // Permanent cache must be empty
      expect(cachedFile.existsSync(), isFalse);
      expect(cachedArt.existsSync(), isFalse);

      // Temporary prefetch file must remain intact
      expect(prefetchedFile.existsSync(), isTrue);
      expect(prefetchedArt.existsSync(), isTrue);
    });

    test('onPositionUpdate respects isPermanentCacheEnabled flag', () async {
      const song = Song(
        id: 'test_song_3',
        title: 'Title',
        artist: 'Artist',
        album: 'Album',
        artworkUrl: '',
        source: 'youtube_music',
        lyrics: null,
        duration: Duration(minutes: 3),
      );

      final prefetchedFile = File(p.join(prefetchDir.path, '${song.id}.prefetch'))..writeAsStringSync('audio_data');

      // Test with disabled setting
      prefetchManager.isPermanentCacheEnabled = false;
      await prefetchManager.onPositionUpdate(song, const Duration(seconds: 160)); // >85%

      final cachedFile = File(p.join(cacheDir.path, '${song.id}.mp3'));
      expect(cachedFile.existsSync(), isFalse);
      expect(prefetchedFile.existsSync(), isTrue);
    });
  });
}
