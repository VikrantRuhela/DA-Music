// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Music Contributors
// Licensed under GPL-3.0.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_credential_store.dart';
import 'youtube_music_account_service.dart';
import 'logger_service.dart';

class SessionManager extends ChangeNotifier {
  final SecureCredentialStore _secureStore;
  
  bool _isLoggedIn = false;
  bool _isGuestMode = false;
  String? _cookies;
  AuthenticatedClient? _client;
  VoidCallback? onSessionExpired;

  bool get isLoggedIn => _isLoggedIn;
  bool get isGuestMode => _isGuestMode;
  String? get cookies => _cookies;
  AuthenticatedClient? get client => _client;

  SessionManager(this._secureStore);

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isGuestMode = prefs.getBool('ytm_guest_mode') ?? false;

      final savedCookies = await _secureStore.readCookies();
      if (savedCookies != null && savedCookies.isNotEmpty) {
        final isValid = await _verifySession(savedCookies);
        if (isValid) {
          _cookies = savedCookies;
          _isLoggedIn = true;
          _isGuestMode = false;
          _client = AuthenticatedClient(savedCookies);
          DALogger.info('SessionManager: Encrypted session successfully restored and validated.');
        } else {
          DALogger.warning('SessionManager: Saved session is expired or invalid. Clearing credentials.');
          await clearSession(notifyExpired: true);
        }
      } else {
        _isLoggedIn = false;
      }
    } catch (e) {
      DALogger.error('SessionManager: Error during session restoration', e);
      _isLoggedIn = false;
    }
    notifyListeners();
  }

  Future<bool> validateAndSaveSession(String cookieHeader) async {
    final cleanCookies = cookieHeader.trim();
    if (cleanCookies.isEmpty) return false;

    final isValid = await _verifySession(cleanCookies);
    if (isValid) {
      await _secureStore.saveCookies(cleanCookies);
      _cookies = cleanCookies;
      _isLoggedIn = true;
      _isGuestMode = false;
      _client = AuthenticatedClient(cleanCookies);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ytm_logged_in', true);
      await prefs.setBool('ytm_guest_mode', false);

      notifyListeners();
      DALogger.info('SessionManager: Session successfully validated and saved to secure storage.');
      return true;
    }
    return false;
  }

  Future<void> setGuestMode(bool value) async {
    _isGuestMode = value;
    if (value) {
      _isLoggedIn = false;
      _cookies = null;
      _client?.close();
      _client = null;
      await _secureStore.clearCookies();
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ytm_guest_mode', value);
    await prefs.setBool('ytm_logged_in', !value && _isLoggedIn);
    
    notifyListeners();
    DALogger.info('SessionManager: Guest mode set to $value.');
  }

  Future<void> clearSession({bool notifyExpired = false}) async {
    _cookies = null;
    _isLoggedIn = false;
    _client?.close();
    _client = null;

    await _secureStore.clearCookies();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ytm_logged_in', false);

    notifyListeners();

    if (notifyExpired && onSessionExpired != null) {
      onSessionExpired!();
    }
  }

  Future<void> logout() async {
    await clearSession();
    _isGuestMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ytm_guest_mode', false);
    notifyListeners();
    DALogger.info('SessionManager: User logged out successfully.');
  }

  Future<bool> _verifySession(String cookies) async {
    final testClient = AuthenticatedClient(cookies);
    try {
      final response = await testClient.post(
        Uri.parse('https://music.youtube.com/youtubei/v1/browse?key=${YouTubeMusicAccountService.apiKey}&prettyPrint=false'),
        body: jsonEncode({
          "context": {
            "client": {
              "clientName": "WEB_REMIX",
              "clientVersion": "1.20250709.01.00",
              "hl": "en",
              "gl": "US"
            }
          },
          "browseId": "FEmusic_home"
        }),
      );

      testClient.close();
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map && !body.containsKey('error')) {
          return true;
        }
      }
    } catch (e) {
      DALogger.error('SessionManager: Session verification failed due to network error', e);
    }
    testClient.close();
    return false;
  }
}
