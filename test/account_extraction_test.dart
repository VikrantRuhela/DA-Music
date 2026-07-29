// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'package:flutter_test/flutter_test.dart';
import 'package:da_tunes/core/services/session_manager.dart';
import 'package:da_tunes/core/services/secure_credential_store.dart';

import 'package:shared_preferences/shared_preferences.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Account Name Extraction Tests', () {
    late SessionManager sessionManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sessionManager = SessionManager(FakeSecureCredentialStore());
      await sessionManager.restoreSession();
    });

    test('setAccountDetails updates state and triggers listeners', () async {
      String? updatedName;
      sessionManager.addListener(() {
        updatedName = sessionManager.accountName;
      });

      await sessionManager.setAccountDetails('DeskAestheticx', 'user@example.com');
      expect(sessionManager.accountName, equals('DeskAestheticx'));
      expect(sessionManager.accountEmail, equals('user@example.com'));
      expect(updatedName, equals('DeskAestheticx'));
    });

    test('Guest mode prioritizes guest username over Google account name', () async {
      await sessionManager.setAccountDetails('GoogleUser', 'user@example.com');
      await sessionManager.updateGuestUsername('CustomGuest');
      await sessionManager.setGuestMode(true);

      expect(sessionManager.isGuestMode, isTrue);
      expect(sessionManager.accountName, equals('CustomGuest'));
    });
  });
}
