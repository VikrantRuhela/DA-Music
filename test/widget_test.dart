import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:da_music/main.dart';
import 'package:da_music/features/home/presentation/widgets/greeting_widget.dart';
import 'package:da_music/features/home/presentation/home_page.dart';
import 'package:da_music/domain/entities/home_feed.dart';
import 'package:da_music/core/services/storage_service.dart';
import 'package:da_music/shared/providers/library_providers.dart';
import 'package:da_music/shared/providers/backend_providers.dart';
import 'package:da_music/core/services/secure_credential_store.dart';

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
    SharedPreferences.setMockInitialValues({'ytm_guest_mode': true});
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          secureStoreProvider.overrideWithValue(FakeSecureCredentialStore()),
          homeFeedProvider.overrideWith((ref) => HomeFeed(
            sections: [
              HomeFeedSection(title: 'Recommended for You', type: 'recommended', items: const []),
              HomeFeedSection(title: 'Trending Albums', type: 'albums', items: const []),
              HomeFeedSection(title: 'Featured Playlists', type: 'playlists', items: const []),
            ],
          )),
        ],
        child: const DAMusicApp(),
      ),
    );

    // Allow navigation/router microtasks to resolve
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    // Verify that our welcome greeting is found on the home page.
    expect(find.byType(GreetingWidget), findsOneWidget);
  });
}
