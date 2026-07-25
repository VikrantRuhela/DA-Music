import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:da_tunes/core/services/storage_service.dart';
import 'package:da_tunes/shared/providers/library_providers.dart';
import 'package:da_tunes/shared/providers/backend_providers.dart';
import 'package:da_tunes/core/services/secure_credential_store.dart';
import 'package:da_tunes/core/services/session_manager.dart';
import 'package:da_tunes/features/taste_engine/presentation/providers/taste_engine_providers.dart';
import 'package:da_tunes/main.dart';
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
  test('Resolve personalizedSectionsProvider Test', () async {
    print('=== RESOLVING PERSONALIZED SECTIONS PROVIDER ===');
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = FallbackHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    
    final sessionManager = SessionManager(FakeSecureCredentialStore());
    await sessionManager.setGuestMode(true);

    final container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(FakeStorageService()),
        sessionManagerProvider.overrideWith((ref) => sessionManager),
      ],
    );

    // Select source 'youtube_music' and initialize it
    print('Registering and selecting source youtube_music...');
    final sourceManager = container.read(sourceManagerProvider);
    await sourceManager.selectSource('youtube_music');

    print('Awaiting personalizedSectionsProvider...');
    try {
      final sections = await container.read(personalizedSectionsProvider.future).timeout(Duration(seconds: 15));
      print('SUCCESS!');
      print('Sections resolved: ${sections.length}');
      for (final s in sections) {
        print('Section: "${s.title}" (type: ${s.type}), Items: ${s.items.length}');
      }
    } catch (e, st) {
      print('FAILED with error: $e');
      print(st);
      fail('Failed to resolve provider: $e');
    }
  });
}
