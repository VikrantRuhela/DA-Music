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

  String? _accountName;
  String? _accountEmail;

  bool get isLoggedIn => _isLoggedIn;
  bool get isGuestMode => _isGuestMode;
  String? get cookies => _cookies;
  AuthenticatedClient? get client => _client;
  String? get accountName => _accountName;
  String? get accountEmail => _accountEmail;

  SessionManager(this._secureStore);

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isGuestMode = prefs.getBool('ytm_guest_mode') ?? false;
      _accountName = prefs.getString('ytm_account_name');
      _accountEmail = prefs.getString('ytm_account_email');

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
      if (_accountName != null) await prefs.setString('ytm_account_name', _accountName!);
      if (_accountEmail != null) await prefs.setString('ytm_account_email', _accountEmail!);

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

    _accountName = null;
    _accountEmail = null;

    await _secureStore.clearCookies();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ytm_logged_in', false);
    await prefs.remove('ytm_account_name');
    await prefs.remove('ytm_account_email');

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
              "clientVersion": "1.20260304.03.00",
              "hl": "en",
              "gl": "US"
            }
          },
          "browseId": "FEmusic_home"
        }),
      );

      testClient.close();
      DALogger.info('SessionManager: Verify session status=${response.statusCode}, body length=${response.body.length}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map && !body.containsKey('error')) {
          String loggedInValue = '0';
          final trackingParams = body['responseContext']?['serviceTrackingParams'] as List?;
          if (trackingParams != null) {
            for (final service in trackingParams) {
              final params = service['params'] as List?;
              if (params != null) {
                for (final p in params) {
                  if (p['key'] == 'logged_in') {
                    loggedInValue = p['value'] as String? ?? '0';
                  }
                }
              }
            }
          }

          DALogger.info('SessionManager: Verification server logged_in value is "$loggedInValue"');

          if (loggedInValue == '1') {
            final accountMenu = body['accountMenu']?['musicAccountMenuRenderer'];
            if (accountMenu != null) {
              final nameText = accountMenu['userName']?['runs']?[0]?['text'] ?? 
                               accountMenu['userName']?['simpleText'] ?? 
                               accountMenu['name']?['runs']?[0]?['text'];
              final emailText = accountMenu['email']?['runs']?[0]?['text'] ?? 
                                accountMenu['email']?['simpleText'];
              _accountName = nameText as String?;
              _accountEmail = emailText as String?;
              DALogger.info('SessionManager: Extracted profile name: $_accountName, email: $_accountEmail');
            }
            return true;
          }
        }
      }
    } catch (e) {
      DALogger.error('SessionManager: Session verification failed due to network error', e);
    }
    return false;
  }
}
