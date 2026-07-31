// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:da_tunes/core/services/playback_prefetch_manager.dart';
import 'package:da_tunes/core/services/stream_resolver.dart';
import 'package:da_tunes/core/services/local_stream_proxy.dart';
import 'package:da_tunes/shared/models/music_models.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeStreamResolver extends Fake implements StreamResolver {}
class FakeLocalStreamProxy extends Fake implements LocalStreamProxy {
  bool manageCacheSizeCalled = false;
  @override
  void manageCacheSize(Directory cacheParent) {
    manageCacheSizeCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlaybackPrefetchManager Tests', () {
    late PlaybackPrefetchManager prefetchManager;
    late FakeStreamResolver fakeResolver;
    late FakeLocalStreamProxy fakeProxy;

    setUp(() {
      const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathChannel, (methodCall) async {
        return '.';
      });

      fakeResolver = FakeStreamResolver();
      fakeProxy = FakeLocalStreamProxy();
      prefetchManager = PlaybackPrefetchManager(fakeResolver, fakeProxy);
    });

    test('updateQueue correctly stores current queue and index', () async {
      final queue = [
        const Song(id: 's1', title: 'Song 1', artist: 'Artist 1', album: 'Album 1', duration: Duration(minutes: 3), artworkUrl: null, source: 'youtube', lyrics: null),
        const Song(id: 's2', title: 'Song 2', artist: 'Artist 2', album: 'Album 2', duration: Duration(minutes: 3), artworkUrl: null, source: 'youtube', lyrics: null),
        const Song(id: 's3', title: 'Song 3', artist: 'Artist 3', album: 'Album 3', duration: Duration(minutes: 3), artworkUrl: null, source: 'youtube', lyrics: null),
        const Song(id: 's4', title: 'Song 4', artist: 'Artist 4', album: 'Album 4', duration: Duration(minutes: 3), artworkUrl: null, source: 'youtube', lyrics: null),
        const Song(id: 's5', title: 'Song 5', artist: 'Artist 5', album: 'Album 5', duration: Duration(minutes: 3), artworkUrl: null, source: 'youtube', lyrics: null),
      ];

      await prefetchManager.updateQueue(queue, 0);

      expect(prefetchManager.currentQueue.length, equals(5));
      expect(prefetchManager.currentIndex, equals(0));
    });

    test('onPositionUpdate does not promote to cache if position is below 85%', () async {
      const song = Song(
        id: 'test_track',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: Duration(seconds: 100),
        artworkUrl: null,
        source: 'youtube',
        lyrics: null,
      );

      // 50 seconds played out of 100 seconds (50% < 85%)
      await prefetchManager.onPositionUpdate(song, const Duration(seconds: 50));
      expect(fakeProxy.manageCacheSizeCalled, isFalse);
    });

    test('onPositionUpdate promotes to cache when position reaches >= 85%', () async {
      final tempDir = await getTemporaryDirectory();
      final prefetchDir = Directory(p.join(tempDir.path, 'da_tunes_prefetch'));
      if (!prefetchDir.existsSync()) prefetchDir.createSync(recursive: true);

      final testFile = File(p.join(prefetchDir.path, 'test_track_85.prefetch'));
      testFile.writeAsStringSync('dummy audio content');

      const song = Song(
        id: 'test_track_85',
        title: 'Test Song 85',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: Duration(seconds: 100),
        artworkUrl: null,
        source: 'youtube',
        lyrics: null,
      );

      // 86 seconds played out of 100 seconds (86% >= 85%)
      await prefetchManager.onPositionUpdate(song, const Duration(seconds: 86));

      // Verify file was moved from prefetch to cache
      final cacheDir = Directory(p.join(tempDir.path, 'da_tunes_cache'));
      final cachedFile = File(p.join(cacheDir.path, 'test_track_85.mp3'));
      expect(cachedFile.existsSync(), isTrue);
      expect(fakeProxy.manageCacheSizeCalled, isTrue);
    });

    test('Progressive Queue Prefetch: prefetch window moves dynamically with currently playing song index', () async {
      final queue = [
        const Song(id: 's1', title: 'Song 1', artist: 'Artist 1', album: 'Album 1', duration: Duration(minutes: 3), artworkUrl: null, source: 'youtube', lyrics: null),
        const Song(id: 's2', title: 'Song 2', artist: 'Artist 2', album: 'Album 2', duration: Duration(minutes: 3), artworkUrl: null, source: 'youtube', lyrics: null),
        const Song(id: 's3', title: 'Song 3', artist: 'Artist 3', album: 'Album 3', duration: Duration(minutes: 3), artworkUrl: null, source: 'youtube', lyrics: null),
        const Song(id: 's4', title: 'Song 4', artist: 'Artist 4', album: 'Album 4', duration: Duration(minutes: 3), artworkUrl: null, source: 'youtube', lyrics: null),
        const Song(id: 's5', title: 'Song 5', artist: 'Artist 5', album: 'Album 5', duration: Duration(minutes: 3), artworkUrl: null, source: 'youtube', lyrics: null),
        const Song(id: 's6', title: 'Song 6', artist: 'Artist 6', album: 'Album 6', duration: Duration(minutes: 3), artworkUrl: null, source: 'youtube', lyrics: null),
      ];

      // At Song 1 (index 0): window is s2, s3, s4
      await prefetchManager.updateQueue(queue, 0);
      expect(prefetchManager.currentIndex, equals(0));

      // Advance to Song 2 (index 1): window moves to s3, s4, s5
      await prefetchManager.updateQueue(queue, 1);
      expect(prefetchManager.currentIndex, equals(1));

      // Direct jump to Song 4 (index 3): window moves to s5, s6
      await prefetchManager.updateQueue(queue, 3);
      expect(prefetchManager.currentIndex, equals(3));
    });
  });
}
