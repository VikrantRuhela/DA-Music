// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Music Contributors
// Licensed under GPL-3.0.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart' as mobile_wv;
import 'package:webview_flutter_windows/webview_flutter_windows.dart' as win_wv;
import '../../../../shared/providers/backend_providers.dart';
import '../../../../core/services/logger_service.dart';

class AuthWebViewPage extends ConsumerStatefulWidget {
  const AuthWebViewPage({super.key});

  @override
  ConsumerState<AuthWebViewPage> createState() => _AuthWebViewPageState();
}

class _AuthWebViewPageState extends ConsumerState<AuthWebViewPage> {
  mobile_wv.WebViewController? _mobileController;
  win_wv.WebviewController? _windowsController;
  StreamSubscription<String>? _urlSubscription;
  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isCheckingSession = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      _initWindowsWebview();
    } else {
      _initMobileWebview();
    }
  }

  Future<void> _initWindowsWebview() async {
    final controller = win_wv.WebviewController();
    try {
      await controller.initialize();
      if (!mounted) return;

      _urlSubscription = controller.url.listen((url) {
        DALogger.info('[Auth Webview] Windows URL changed: $url');
        _checkForRedirect(url);
      });

      controller.loadingState.listen((state) {
        if (mounted) {
          setState(() {
            _isLoading = state == win_wv.LoadingState.loading;
          });
        }
        _checkWindowsCookiesQuick();
      });

      // Start periodic polling timer (1 second interval) to catch authentication tokens immediately
      _pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!mounted || _isCheckingSession) return;
        await _checkWindowsCookiesQuick();
      });

      await controller.loadUrl(
        'https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&passive=true&continue=https://music.youtube.com/',
      );

      if (mounted) {
        setState(() {
          _windowsController = controller;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      DALogger.error('[Auth Webview] Failed to initialize Windows WebviewController', e, s);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkWindowsCookiesQuick() async {
    if (_windowsController == null || _isCheckingSession) return;
    try {
      final cookies = await _windowsController!.getCookies('https://music.youtube.com');
      final hasKeys = cookies.any((c) =>
          c.name == '__Secure-3PAPISID' ||
          c.name == '__Secure-3PSID' ||
          c.name == 'SID' ||
          c.name == 'SAPISID');
      if (hasKeys) {
        _checkForRedirect('https://music.youtube.com');
      }
    } catch (_) {}
  }

  void _initMobileWebview() {
    const userAgent =
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

    final controller = mobile_wv.WebViewController()
      ..setJavaScriptMode(mobile_wv.JavaScriptMode.unrestricted)
      ..setUserAgent(userAgent)
      ..setNavigationDelegate(
        mobile_wv.NavigationDelegate(
          onPageStarted: (url) {
            DALogger.info('[Auth Webview] Mobile page started: $url');
            setState(() {
              _isLoading = true;
            });
            _checkForRedirect(url);
          },
          onPageFinished: (url) {
            DALogger.info('[Auth Webview] Mobile page finished: $url');
            setState(() {
              _isLoading = false;
            });
            _checkForRedirect(url);
          },
          onNavigationRequest: (request) {
            DALogger.info('[Auth Webview] Mobile navigation request to: ${request.url}');
            _checkForRedirect(request.url);
            return mobile_wv.NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&passive=true&continue=https://music.youtube.com/',
        ),
      );

    _mobileController = controller;
  }

  Future<void> _checkForRedirect(String url) async {
    if (_isCheckingSession) return;

    if (url.startsWith('https://music.youtube.com')) {
      _isCheckingSession = true;
      DALogger.info('[Auth Webview] Redirect to music.youtube.com detected. Extracting cookies...');

      try {
        String cookieString = '';

        if (Platform.isWindows && _windowsController != null) {
          final List<win_wv.WebviewCookie> allWinCookies = [];
          final Set<String> names = {};

          final domains = [
            'https://music.youtube.com',
            'https://youtube.com',
            'https://.youtube.com',
            'https://accounts.google.com',
            'https://google.com',
            'https://.google.com',
            '',
          ];

          for (final domainStr in domains) {
            try {
              final cookies = await _windowsController!.getCookies(domainStr);
              DALogger.info('[Auth Webview] Windows getCookies("$domainStr") returned ${cookies.length} cookies.');
              for (final c in cookies) {
                if (!names.contains(c.name)) {
                  names.add(c.name);
                  allWinCookies.add(c);
                }
              }
            } catch (e) {
              DALogger.error('[Auth Webview] Windows failed to get cookies for $domainStr', e);
            }
          }

          cookieString = allWinCookies.map((c) => '${c.name}=${c.value}').join('; ');
        } else {
          final cookieManager = mobile_wv.WebViewCookieManager();
          final List<mobile_wv.WebViewCookie> allCookies = [];
          final Set<String> names = {};

          final domains = [
            'https://music.youtube.com',
            'https://youtube.com',
            'https://.youtube.com',
            'https://accounts.google.com',
            'https://google.com',
            'https://.google.com',
          ];

          for (final domainStr in domains) {
            try {
              final cookies = await cookieManager.getCookies(domain: Uri.parse(domainStr));
              for (final c in cookies) {
                if (!names.contains(c.name)) {
                  names.add(c.name);
                  allCookies.add(c);
                }
              }
            } catch (e) {
              DALogger.error('[Auth Webview] Mobile failed to get cookies for domain $domainStr', e);
            }
          }

          cookieString = allCookies.map((c) => '${c.name}=${c.value}').join('; ');
        }

        final hasKeys =
            cookieString.contains('__Secure-3PAPISID') ||
            cookieString.contains('__Secure-3PSID') ||
            cookieString.contains('SID') ||
            cookieString.contains('SAPISID');

        DALogger.info('[Auth Webview] Combined cookies length: ${cookieString.length}. Has core keys: $hasKeys');

        if (hasKeys) {
          final sessionManager = ref.read(sessionManagerProvider);
          final success = await sessionManager.validateAndSaveSession(cookieString);
          DALogger.info('[Auth Webview] Session validation result: $success');

          if (success && mounted) {
            _pollTimer?.cancel();
            Navigator.of(context).pop(true);
            return;
          }
        }
      } catch (e, s) {
        DALogger.error('[Auth Webview] Exception during cookie extraction', e, s);
      } finally {
        _isCheckingSession = false;
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _urlSubscription?.cancel();
    _windowsController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in to YouTube Music'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (Platform.isWindows)
            _windowsController != null && _windowsController!.value.isInitialized
                ? win_wv.Webview(_windowsController!)
                : const SizedBox.shrink()
          else if (_mobileController != null)
            mobile_wv.WebViewWidget(controller: _mobileController!),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
