import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:da_tunes/core/services/session_manager.dart';
import 'package:da_tunes/core/services/secure_credential_store.dart';
import 'package:da_tunes/features/taste_engine/domain/music_dna.dart';
import 'package:da_tunes/features/taste_engine/domain/taste_analyzer.dart';
import 'package:da_tunes/features/taste_engine/presentation/providers/taste_engine_providers.dart';
import 'package:da_tunes/shared/providers/backend_providers.dart';
import 'package:da_tunes/core/services/storage_service.dart';
import 'package:da_tunes/shared/providers/library_providers.dart';

class FakeSecureCredentialStore implements SecureCredentialStore {
  String? _cookies;

  @override
  Future<void> clearCookies() async {
    _cookies = null;
  }

  @override
  Future<String?> readCookies() async {
    return _cookies;
  }

  @override
  Future<void> saveCookies(String cookies) async {
    _cookies = cookies;
  }
}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Guest Onboarding System Tests', () {
    late SessionManager sessionManager;
    late FakeSecureCredentialStore fakeSecureStore;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fakeSecureStore = FakeSecureCredentialStore();
      sessionManager = SessionManager(fakeSecureStore);
      await sessionManager.restoreSession();
    });

    test('Default Session State matches Guest mode and Voyager defaults', () async {
      expect(sessionManager.isGuestMode, isFalse);
      expect(sessionManager.isGuestOnboardingCompleted, isFalse);
      expect(sessionManager.guestUsername, equals('Voyager'));
    });

    test('Onboarding Complete modifies flags and updates username', () async {
      await sessionManager.setGuestMode(true);
      await sessionManager.updateGuestUsername('Vikrant');
      await sessionManager.completeGuestOnboarding();

      expect(sessionManager.isGuestMode, isTrue);
      expect(sessionManager.isGuestOnboardingCompleted, isTrue);
      expect(sessionManager.guestUsername, equals('Vikrant'));
      expect(sessionManager.accountName, equals('Vikrant'));
    });

    test('Reset Onboarding clears all flags and resets username to Voyager', () async {
      await sessionManager.setGuestMode(true);
      await sessionManager.updateGuestUsername('Vikrant');
      await sessionManager.completeGuestOnboarding();

      await sessionManager.resetGuestOnboarding();

      expect(sessionManager.isGuestOnboardingCompleted, isFalse);
      expect(sessionManager.guestUsername, equals('Voyager'));
      expect(sessionManager.accountName, equals('Voyager'));
    });

    test('MusicDNA validation for custom Guest preferences', () {
      final dna = const MusicDNA(
        topArtists: [],
        favoriteGenres: [],
        favoriteLanguages: [],
      );

      final guestGenres = ['Punjabi', 'Hip-Hop'];
      final guestArtists = ['Karan Aujla', 'Shubh'];

      final mergedTopArtists = List<String>.from(dna.topArtists);
      for (final artist in guestArtists) {
        if (!mergedTopArtists.contains(artist)) {
          mergedTopArtists.add(artist);
        }
      }
      
      final mergedFavoriteGenres = List<String>.from(dna.favoriteGenres);
      for (final genre in guestGenres) {
        if (!mergedFavoriteGenres.contains(genre)) {
          mergedFavoriteGenres.add(genre);
        }
      }

      final Map<String, double> mergedArtistAffinities = Map<String, double>.from(dna.artistAffinities);
      for (final artist in guestArtists) {
        mergedArtistAffinities[artist] = (mergedArtistAffinities[artist] ?? 0.0) + 1.0;
      }

      final Map<String, double> mergedGenreAffinities = Map<String, double>.from(dna.genreAffinities);
      for (final genre in guestGenres) {
        mergedGenreAffinities[genre] = (mergedGenreAffinities[genre] ?? 0.0) + 1.0;
      }

      final supplementedDna = MusicDNA(
        topArtists: mergedTopArtists,
        favoriteGenres: mergedFavoriteGenres,
        artistAffinities: mergedArtistAffinities,
        genreAffinities: mergedGenreAffinities,
      );

      expect(supplementedDna.topArtists, containsAll(['Karan Aujla', 'Shubh']));
      expect(supplementedDna.favoriteGenres, containsAll(['Punjabi', 'Hip-Hop']));
      expect(supplementedDna.artistAffinities['Karan Aujla'], equals(1.0));
      expect(supplementedDna.genreAffinities['Punjabi'], equals(1.0));
    });

    test('TasteEngineNotifier reload updates DNA from SharedPreferences guest values', () async {
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
        return '.';
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('ytm_guest_genres', ['Punjabi', 'Hip-Hop']);
      await prefs.setStringList('ytm_guest_artists', ['Karan Aujla', 'Diljit Dosanjh']);
      await prefs.setString('ytm_guest_region', 'India');

      final container = ProviderContainer(
        overrides: [
          secureStoreProvider.overrideWithValue(FakeSecureCredentialStore()),
          storageServiceProvider.overrideWithValue(FakeStorageService()),
        ],
      );
      addTearDown(container.dispose);

      final sm = container.read(sessionManagerProvider);
      await sm.setGuestMode(true);

      final notifier = container.read(tasteEngineNotifierProvider.notifier);
      await notifier.reload();

      final state = container.read(tasteEngineNotifierProvider);

      expect(state.dna.favoriteGenres, containsAll(['Punjabi', 'Hip-Hop']));
      expect(state.dna.topArtists, containsAll(['Karan Aujla', 'Diljit Dosanjh']));
    });
  });
}
