// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:da_tunes/app/theme/theme.dart';
import 'package:da_tunes/core/services/storage_service.dart';
import 'package:da_tunes/core/services/playback_controller.dart';
import 'package:da_tunes/shared/models/music_models.dart';
import 'package:da_tunes/shared/models/playback_state.dart';
import 'package:da_tunes/shared/providers/library_providers.dart';
import 'package:da_tunes/shared/providers/player_providers.dart';
import 'package:da_tunes/features/player/presentation/widgets/immersive/immersive_player.dart';

class FakeStorageService implements StorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> init() async {}

  @override
  Future<String?> getString(String key) async => _data[key];

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }
}

class FakePlaybackController extends ChangeNotifier implements PlaybackController {
  @override
  PlaybackStatus get status => PlaybackStatus.playing;

  @override
  Duration get position => const Duration(seconds: 30);

  @override
  double get bufferProgress => 0.8;

  @override
  Song? get currentSong => const Song(
        id: 'song1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: Duration(minutes: 3),
        artworkUrl: null,
        source: 'local',
        lyrics: null,
      );

  @override
  List<QueueItem> get queue => [];

  @override
  PlayerSettings get settings => const PlayerSettings();

  @override
  void noSuchMethod(Invocation invocation) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('All Player Styles Expansion & Architecture Tests', () {
    testWidgets('ImmersivePlayer builds correctly for PlayerStyle.immersive', (tester) async {
      final fakeStorage = FakeStorageService();
      final fakeController = FakePlaybackController();

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(fakeStorage),
          playbackControllerProvider.overrideWith((ref) => fakeController),
          currentSongProvider.overrideWithValue(fakeController.currentSong),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: DATheme.darkTheme,
            home: const Scaffold(
              body: ImmersivePlayer(),
            ),
          ),
        ),
      );

      expect(find.byType(ImmersivePlayer), findsOneWidget);
    });

    testWidgets('ImmersivePlayer builds correctly for PlayerStyle.vinyl', (tester) async {
      final fakeStorage = FakeStorageService();
      final fakeController = FakePlaybackController();

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(fakeStorage),
          playbackControllerProvider.overrideWith((ref) => fakeController),
          currentSongProvider.overrideWithValue(fakeController.currentSong),
        ],
      );
      addTearDown(container.dispose);
      container.read(playerStyleProvider.notifier).setStyle(PlayerStyle.vinyl);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: DATheme.darkTheme,
            home: const Scaffold(
              body: ImmersivePlayer(),
            ),
          ),
        ),
      );

      expect(find.byType(ImmersivePlayer), findsOneWidget);
    });

    testWidgets('ImmersivePlayer builds correctly for PlayerStyle.minimal', (tester) async {
      final fakeStorage = FakeStorageService();
      final fakeController = FakePlaybackController();

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(fakeStorage),
          playbackControllerProvider.overrideWith((ref) => fakeController),
          currentSongProvider.overrideWithValue(fakeController.currentSong),
        ],
      );
      addTearDown(container.dispose);
      container.read(playerStyleProvider.notifier).setStyle(PlayerStyle.minimal);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: DATheme.darkTheme,
            home: const Scaffold(
              body: ImmersivePlayer(),
            ),
          ),
        ),
      );

      expect(find.byType(ImmersivePlayer), findsOneWidget);
      expect(find.byIcon(Icons.queue_music), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });
  });
}
