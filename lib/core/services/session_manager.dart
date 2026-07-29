// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
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

  bool _isGuestOnboardingCompleted = false;
  String? _guestUsername;
  String? _guestProfileId;

  bool get isLoggedIn => _isLoggedIn;
  bool get isGuestMode => _isGuestMode;
  String? get cookies => _cookies;
  AuthenticatedClient? get client => _client;
  String? get accountName => _isGuestMode ? _guestUsername : _accountName;
  String? get accountEmail => _accountEmail;
  bool get isGuestOnboardingCompleted => _isGuestOnboardingCompleted;
  String? get guestUsername => _guestUsername;
  String? get guestProfileId => _guestProfileId;

  SessionManager(this._secureStore);

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isGuestMode = prefs.getBool('ytm_guest_mode') ?? false;
      _accountName = prefs.getString('ytm_account_name');
      _accountEmail = prefs.getString('ytm_account_email');
      _isGuestOnboardingCompleted = prefs.getBool('ytm_guest_onboarding_completed') ?? false;
      _guestUsername = prefs.getString('ytm_guest_username') ?? 'Voyager';
      _guestProfileId = prefs.getString('ytm_guest_profile_id');

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
    
    if (value && (_guestProfileId == null || _guestProfileId!.isEmpty)) {
      _guestProfileId = 'Guest_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('ytm_guest_profile_id', _guestProfileId!);
      DALogger.info('[GUEST PROFILE] Created Guest Profile. ID: $_guestProfileId');
    }
    
    notifyListeners();
    DALogger.info('SessionManager: Guest mode set to $value.');
  }

  Future<void> updateGuestUsername(String name) async {
    _guestUsername = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ytm_guest_username', name);
    notifyListeners();
  }

  Future<void> setAccountDetails(String? name, String? email) async {
    bool changed = false;
    if (name != null && name.isNotEmpty && name != _accountName) {
      _accountName = name;
      changed = true;
    }
    if (email != null && email.isNotEmpty && email != _accountEmail) {
      _accountEmail = email;
      changed = true;
    }
    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      if (_accountName != null) await prefs.setString('ytm_account_name', _accountName!);
      if (_accountEmail != null) await prefs.setString('ytm_account_email', _accountEmail!);
      notifyListeners();
      DALogger.info('SessionManager: Account details updated — name: $_accountName, email: $_accountEmail');
    }
  }

  Future<void> completeGuestOnboarding() async {
    _isGuestOnboardingCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ytm_guest_onboarding_completed', true);
    DALogger.info('[GUEST PROFILE] Onboarding completed. Preferences saved for ID: $_guestProfileId');
    notifyListeners();
  }

  Future<void> resetGuestOnboarding() async {
    _isGuestOnboardingCompleted = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ytm_guest_onboarding_completed', false);
    await prefs.remove('ytm_guest_username');
    await prefs.remove('ytm_guest_languages');
    await prefs.remove('ytm_guest_region');
    await prefs.remove('ytm_guest_genres');
    await prefs.remove('ytm_guest_artists');
    await prefs.remove('ytm_guest_profile_id');
    await prefs.remove('ytm_cache_personalized_sections');
    _guestProfileId = null;
    _guestUsername = 'Voyager';
    DALogger.info('[GUEST PROFILE] Guest Profile reset.');
    notifyListeners();
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
      ).timeout(const Duration(seconds: 10));

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

          final bodyStr = response.body;
          final isExplicitLoggedIn = loggedInValue == '1' ||
              bodyStr.contains('"logged_in":"1"') ||
              bodyStr.contains('"LOGGED_IN"') ||
              bodyStr.contains('accountMenu');

          DALogger.info('SessionManager: Verification server logged_in value is "$loggedInValue", isExplicitLoggedIn=$isExplicitLoggedIn');

          if (isExplicitLoggedIn) {
            // Try to extract account name from browse response (deep search)
            _extractAccountFromResponse(body);

            // If name still not found, try dedicated account_menu endpoint
            if (_accountName == null || _accountName!.isEmpty) {
              await _fetchAccountMenu(testClient);
            }

            // Persist extracted name/email
            if (_accountName != null || _accountEmail != null) {
              final prefs = await SharedPreferences.getInstance();
              if (_accountName != null) await prefs.setString('ytm_account_name', _accountName!);
              if (_accountEmail != null) await prefs.setString('ytm_account_email', _accountEmail!);
            }

            testClient.close();
            return true;
          }
        }
      }
    } catch (e) {
      DALogger.error('SessionManager: Session verification failed due to network error', e);
    }
    testClient.close();
    return false;
  }

  /// Deep-search the entire InnerTube response for musicAccountMenuRenderer
  void _extractAccountFromResponse(dynamic node) {
    if (_accountName != null && _accountName!.isNotEmpty) return;
    if (node is Map) {
      if (node.containsKey('musicAccountMenuRenderer')) {
        _tryExtractFromRenderer(node['musicAccountMenuRenderer']);
      }
      if (node.containsKey('musicCarouselShelfBasicHeaderRenderer')) {
        final header = node['musicCarouselShelfBasicHeaderRenderer'];
        if (header is Map) {
          final strapline = header['strapline']?['runs']?[0]?['text'] as String?;
          if (strapline != null && strapline.isNotEmpty && !strapline.contains('YouTube') && strapline.length < 50) {
            _accountName = strapline;
          }
        }
      }
      if (node.containsKey('accountName') || node.containsKey('accountPhotoUrl')) {
        _tryExtractFromRenderer(node);
      }
      for (final value in node.values) {
        _extractAccountFromResponse(value);
        if (_accountName != null && _accountName!.isNotEmpty) return;
      }
    } else if (node is List) {
      for (final item in node) {
        _extractAccountFromResponse(item);
        if (_accountName != null && _accountName!.isNotEmpty) return;
      }
    }
  }

  void _tryExtractFromRenderer(dynamic renderer) {
    if (renderer is! Map) return;

    final nameText = renderer['userName']?['runs']?[0]?['text'] ??
                     renderer['userName']?['simpleText'] ??
                     renderer['accountName']?['runs']?[0]?['text'] ??
                     renderer['accountName']?['simpleText'] ??
                     renderer['name']?['runs']?[0]?['text'] ??
                     renderer['name']?['simpleText'] ??
                     renderer['accountName'];
    if (nameText is String && nameText.isNotEmpty) {
      _accountName = nameText;
    }

    final emailText = renderer['email']?['runs']?[0]?['text'] ??
                      renderer['email']?['simpleText'] ??
                      renderer['accountByline']?['runs']?[0]?['text'] ??
                      renderer['accountByline']?['simpleText'] ??
                      renderer['email'];
    if (emailText is String && emailText.isNotEmpty) {
      _accountEmail = emailText;
    }

    if (_accountName == null || _accountName!.isEmpty) {
      final channelHandle = renderer['channelHandle']?['runs']?[0]?['text'] ??
                            renderer['channelHandle']?['simpleText'];
      if (channelHandle is String && channelHandle.isNotEmpty) {
        _accountName = channelHandle;
      }
    }

    DALogger.info('SessionManager: Extracted profile name: $_accountName, email: $_accountEmail');
  }

  Future<void> _fetchAccountMenu(AuthenticatedClient client) async {
    try {
      final switcherResponse = await client.get(
        Uri.parse('https://music.youtube.com/getAccountSwitcherEndpoint'),
      ).timeout(const Duration(seconds: 8));

      if (switcherResponse.statusCode == 200) {
        String cleanBody = switcherResponse.body;
        if (cleanBody.startsWith(")]}'\n")) {
          cleanBody = cleanBody.substring(5);
        } else if (cleanBody.startsWith(")]}'")) {
          cleanBody = cleanBody.substring(4);
        }
        final body = jsonDecode(cleanBody);
        DALogger.info('SessionManager: getAccountSwitcherEndpoint response received, size=${cleanBody.length}');
        _extractAccountFromResponse(body);
      }
    } catch (e) {
      DALogger.warning('SessionManager: getAccountSwitcherEndpoint failed: $e');
    }

    if (_accountName != null && _accountName!.isNotEmpty) return;

    try {
      final response = await client.post(
        Uri.parse('https://music.youtube.com/youtubei/v1/account/account_menu?key=${YouTubeMusicAccountService.apiKey}&prettyPrint=false'),
        body: jsonEncode({
          "context": {
            "client": {
              "clientName": "WEB_REMIX",
              "clientVersion": "1.20260304.03.00",
              "hl": "en",
              "gl": "US"
            }
          }
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        DALogger.info('SessionManager: account_menu response received, size=${response.body.length}');
        _extractAccountFromResponse(body);

        if ((_accountName == null || _accountName!.isEmpty) && body is Map) {
          final actions = body['actions'] as List?;
          if (actions != null) {
            for (final action in actions) {
              final renderer = action['openPopupAction']?['popup']?['multiPageMenuRenderer'];
              if (renderer != null) {
                _extractAccountFromResponse(renderer);
                if (_accountName != null && _accountName!.isNotEmpty) break;
              }
            }
          }

          final header = body['header']?['activeAccountHeaderRenderer'] ??
                         body['header']?['googleAccountHeaderRenderer'] ??
                         body['header']?['c4TabbedHeaderRenderer'];
          if (header is Map) {
            final name = header['accountName']?['runs']?[0]?['text'] ??
                         header['accountName']?['simpleText'] ??
                         header['channelName'] ??
                         header['title']?['runs']?[0]?['text'] ??
                         header['title']?['simpleText'];
            if (name is String && name.isNotEmpty) {
              _accountName = name;
            }
            final email = header['email']?['runs']?[0]?['text'] ??
                          header['email']?['simpleText'] ??
                          header['accountByline']?['runs']?[0]?['text'] ??
                          header['accountByline']?['simpleText'];
            if (email is String && email.isNotEmpty) {
              _accountEmail = email;
            }
            DALogger.info('SessionManager: Extracted from header — name: $_accountName, email: $_accountEmail');
          }
        }
      }
    } catch (e) {
      DALogger.warning('SessionManager: account_menu fallback request failed: $e');
    }
  }
}
