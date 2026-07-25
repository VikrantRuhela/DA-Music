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
      setState(() {
        _isCheckingSession = true;
        _isLoading = true;
      });
      DALogger.info('[Auth Webview] Redirect to music.youtube.com detected. Extracting cookies...');

      try {
        String cookieString = '';

        if (Platform.isWindows && _windowsController != null) {
          try {
            final cookies = await _windowsController!.getCookies('https://music.youtube.com');
            DALogger.info('[Auth Webview] Windows getCookies("https://music.youtube.com") returned ${cookies.length} cookies.');
            cookieString = cookies.map((c) => '${c.name}=${c.value}').join('; ');
          } catch (e) {
            DALogger.error('[Auth Webview] Windows failed to get cookies', e);
          }
        } else {
          final cookieManager = mobile_wv.WebViewCookieManager();
          try {
            final cookies = await cookieManager.getCookies(domain: Uri.parse('https://music.youtube.com'));
            DALogger.info('[Auth Webview] Mobile getCookies("https://music.youtube.com") returned ${cookies.length} cookies.');
            cookieString = cookies.map((c) => '${c.name}=${c.value}').join('; ');
          } catch (e) {
            DALogger.error('[Auth Webview] Mobile failed to get cookies', e);
          }
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
            Navigator.of(context).pop(true);
            return;
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to verify session. Please try logging in again.'),
                  backgroundColor: Colors.redAccent,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        } else {
          DALogger.warning('[Auth Webview] music.youtube.com reached but core keys were missing in cookies.');
        }
      } catch (e, s) {
        DALogger.error('[Auth Webview] Exception during cookie extraction', e, s);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error during session verification: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isCheckingSession = false;
            _isLoading = false;
          });
        }
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
          if (_isLoading || _isCheckingSession)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      _isCheckingSession ? 'Verifying session, please wait...' : 'Loading login page...',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
