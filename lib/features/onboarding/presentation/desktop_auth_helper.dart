import 'package:desktop_webview_window/desktop_webview_window.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/logger_service.dart';

class DesktopAuthHelper {
  static Future<bool> isWebviewAvailable() async {
    try {
      return await WebviewWindow.isWebviewAvailable();
    } catch (_) {
      return false;
    }
  }

  static Future<void> loginWithDesktopWebview(SessionManager sessionManager, {required Function(bool) onFinished}) async {
    try {
      final isAvailable = await isWebviewAvailable();
      if (!isAvailable) {
        DALogger.error('DesktopAuthHelper: WebView2 runtime is not available on this Windows host.');
        onFinished(false);
        return;
      }

      final webview = await WebviewWindow.create(
        configuration: const CreateConfiguration(
          title: 'Sign in to YouTube Music',
          windowWidth: 600,
          windowHeight: 800,
        ),
      );

      webview.launch('https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&passive=true&continue=https://music.youtube.com/');
      await webview.setWebviewWindowVisibility(true);

      webview.addOnUrlRequestCallback((url) async {
        if (url.startsWith('https://music.youtube.com')) {
          final cookiesJson = await webview.evaluateJavaScript('document.cookie');
          if (cookiesJson != null) {
            String cookies = cookiesJson;
            // Clean up serialized JSON response from JS engine evaluation
            if (cookies.startsWith('"') && cookies.endsWith('"')) {
              cookies = cookies.substring(1, cookies.length - 1);
            }
            // Unescape escaped hex symbols if any
            cookies = cookies.replaceAll(r'\"', '"');

            if (cookies.contains('__Secure-3PAPISID') || cookies.contains('__Secure-3PSID') || cookies.contains('SID')) {
              final success = await sessionManager.validateAndSaveSession(cookies);
              if (success) {
                webview.close();
                onFinished(true);
              }
            }
          }
        }
      });
    } catch (e) {
      DALogger.error('DesktopAuthHelper: Windows WebView2 login error', e);
      onFinished(false);
    }
  }
}
