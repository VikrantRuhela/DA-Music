// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:da_tunes/core/services/session_manager.dart';
import 'package:da_tunes/core/services/secure_credential_store.dart';

class FakeSecureCredentialStore extends Fake implements SecureCredentialStore {
  String? storedCookies;

  @override
  Future<String?> readCookies() async => storedCookies;

  @override
  Future<void> saveCookies(String cookies) async {
    storedCookies = cookies;
  }

  @override
  Future<void> clearCookies() async {
    storedCookies = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionManager Network Resilience Tests', () {
    late SessionManager sessionManager;
    late FakeSecureCredentialStore fakeSecureStore;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fakeSecureStore = FakeSecureCredentialStore();
      sessionManager = SessionManager(fakeSecureStore);
    });

    test('SessionVerificationResult enum contains networkError', () {
      expect(SessionVerificationResult.networkError, isNotNull);
      expect(SessionVerificationResult.valid, isNotNull);
      expect(SessionVerificationResult.unauthenticated, isNotNull);
    });

    test('restoreSession retains cookies and logged in state on network verification error', () async {
      // Simulate stored cookies in encrypted store
      fakeSecureStore.storedCookies = '__Secure-3PAPISID=dummy_sapisid; SID=dummy_sid';

      // Restore session (which encounters a network error since server is mock/unreachable)
      await sessionManager.restoreSession();

      // Verify that stored cookies were NOT wiped out by network failure
      expect(sessionManager.isLoggedIn, isTrue);
      expect(sessionManager.cookies, equals('__Secure-3PAPISID=dummy_sapisid; SID=dummy_sid'));
      expect(fakeSecureStore.storedCookies, isNotNull);
    });
  });
}
