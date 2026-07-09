import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../shared/providers/backend_providers.dart';

class AuthWebViewPage extends ConsumerStatefulWidget {
  const AuthWebViewPage({super.key});

  @override
  ConsumerState<AuthWebViewPage> createState() => _AuthWebViewPageState();
}

class _AuthWebViewPageState extends ConsumerState<AuthWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Standard User-Agent to pass Google security check
    const userAgent = 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
            });
            _checkForRedirect(url);
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
            _checkForRedirect(url);
          },
          onNavigationRequest: (request) {
            _checkForRedirect(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&passive=true&continue=https://music.youtube.com/'));
  }

  Future<void> _checkForRedirect(String url) async {
    if (url.startsWith('https://music.youtube.com')) {
      final cookieManager = WebViewCookieManager();
      final cookies = await cookieManager.getCookies(domain: Uri.parse('https://music.youtube.com'));
      final cookieString = cookies.map((c) => '${c.name}=${c.value}').join('; ');

      if (cookieString.contains('__Secure-3PAPISID') || cookieString.contains('__Secure-3PSID') || cookieString.contains('SID')) {
        final sessionManager = ref.read(sessionManagerProvider);
        final success = await sessionManager.validateAndSaveSession(cookieString);
        if (success) {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        }
      }
    }
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
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
