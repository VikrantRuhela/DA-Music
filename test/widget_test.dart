import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:da_tunes/main.dart';
import 'package:da_tunes/features/home/presentation/widgets/greeting_widget.dart';
import 'package:da_tunes/features/home/presentation/home_page.dart';
import 'package:da_tunes/domain/entities/home_feed.dart';
import 'package:da_tunes/core/services/storage_service.dart';
import 'package:da_tunes/shared/providers/library_providers.dart';
import 'package:da_tunes/shared/providers/backend_providers.dart';
import 'package:da_tunes/core/services/secure_credential_store.dart';
import 'package:da_tunes/core/services/session_manager.dart';
import 'package:da_tunes/features/taste_engine/presentation/providers/taste_engine_providers.dart';

import 'package:shared_preferences/shared_preferences.dart';

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
class FakeSecureCredentialStore extends SecureCredentialStore {
  String? _cookies;
  @override
  Future<void> saveCookies(String cookies) async {
    _cookies = cookies;
  }
  @override
  Future<String?> readCookies() async => _cookies;
  @override
  Future<void> clearCookies() async {
    _cookies = null;
  }
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      return '.';
    });

    final sessionManager = SessionManager(FakeSecureCredentialStore());
    await sessionManager.restoreSession();
    await sessionManager.setGuestMode(true);
    await sessionManager.completeGuestOnboarding();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          sessionManagerProvider.overrideWith((ref) => sessionManager),
          homeFeedProvider.overrideWith((ref) => HomeFeed(
            sections: [
              HomeFeedSection(title: 'Recommended for You', type: 'recommended', items: const []),
              HomeFeedSection(title: 'Trending Albums', type: 'albums', items: const []),
              HomeFeedSection(title: 'Featured Playlists', type: 'playlists', items: const []),
            ],
          )),
          personalizedSectionsProvider.overrideWith((ref) => [
            const RecommendationSection(
              title: 'Recommended for You',
              subtitle: 'Popular tracks picked for you',
              type: 'trending',
              items: [],
            ),
          ]),
        ],
        child: const DAMusicApp(),
      ),
    );

    // Allow navigation/router microtasks to resolve
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify that our welcome greeting is found on the home page.
    expect(find.byType(GreetingWidget), findsOneWidget);
  });
}
