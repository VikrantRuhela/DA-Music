import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router/router.dart';
import 'app/theme/dynamic_theme_provider.dart';
import 'core/services/platform_service.dart';
import 'core/services/windows_platform_service.dart';
import 'core/services/default_platform_service.dart';
import 'core/services/json_storage_service.dart';
import 'shared/providers/library_providers.dart';
import 'shared/providers/backend_providers.dart';
import 'core/services/system_media_session_manager.dart';
import 'core/services/session_manager.dart';
import 'shared/providers/player_providers.dart';

import 'package:desktop_webview_window/desktop_webview_window.dart';

class FallbackHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory = (Uri url, String? proxyHost, int? proxyPort) async {
      final host = proxyHost ?? url.host;
      final port = proxyPort ?? (url.port != 0 ? url.port : (url.scheme == 'https' ? 443 : 80));
      
      Socket socket;
      try {
        // Try standard dual-stack connection first (crucial for IPv6-only networks like Jio) with a fail-fast 1.5s timeout
        socket = await Socket.connect(host, port).timeout(const Duration(milliseconds: 1500));
      } catch (_) {
        try {
          final addresses = await InternetAddress.lookup(host, type: InternetAddressType.IPv4);
          if (addresses.isNotEmpty) {
            socket = await Socket.connect(addresses.first, port);
          } else {
            rethrow;
          }
        } catch (e2) {
          socket = await Socket.connect(host, port);
        }
      }

      if (url.scheme.toLowerCase() == 'https') {
        final secureSocket = await SecureSocket.secure(socket, host: host);
        return ConnectionTask.fromSocket(Future.value(secureSocket), () {});
      }
      return ConnectionTask.fromSocket(Future.value(socket), () {});
    };
    return client;
  }
}

void main([List<String> args = const []]) async {
  HttpOverrides.global = FallbackHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    if (runWebViewTitleBarWidget(args)) {
      return;
    }
  }

  final PlatformService platformService = !kIsWeb && Platform.isWindows
      ? WindowsPlatformService()
      : DefaultPlatformService();

  await platformService.initializeWindow();

  final storageService = JsonStorageService();
  await storageService.init();

  final container = ProviderContainer(
    overrides: [
      storageServiceProvider.overrideWithValue(storageService),
    ],
  );

  if (!kIsWeb && Platform.isWindows) {
    WindowsPlatformService.onShutdown = () async {
      final startTime = DateTime.now();
      debugPrint(' [Shutdown] Starting clean shutdown sequence...');

      // 1. Stop audio player
      final stopPlayerTime = DateTime.now();
      try {
        final playbackEngine = container.read(playbackEngineProvider);
        await playbackEngine.dispose();
        debugPrint(' [Shutdown] Audio player disposed in ${DateTime.now().difference(stopPlayerTime).inMilliseconds}ms');
      } catch (e) {
        debugPrint(' [Shutdown] Audio player disposal failed: $e');
      }

      // 2. Stop local stream proxy
      final stopProxyTime = DateTime.now();
      try {
        final proxy = container.read(localStreamProxyProvider);
        await proxy.stop();
        debugPrint(' [Shutdown] Local stream proxy stopped in ${DateTime.now().difference(stopProxyTime).inMilliseconds}ms');
      } catch (e) {
        debugPrint(' [Shutdown] Local stream proxy stop failed: $e');
      }

      // 3. Close database connection
      final stopDbTime = DateTime.now();
      try {
        final db = container.read(appDatabaseProvider);
        await db.close();
        debugPrint(' [Shutdown] Database closed in ${DateTime.now().difference(stopDbTime).inMilliseconds}ms');
      } catch (e) {
        debugPrint(' [Shutdown] Database close failed: $e');
      }

      // 4. Dispose ProviderContainer
      final disposeContainerTime = DateTime.now();
      container.dispose();
      debugPrint(' [Shutdown] Riverpod container disposed in ${DateTime.now().difference(disposeContainerTime).inMilliseconds}ms');

      debugPrint(' [Shutdown] Clean shutdown completed in ${DateTime.now().difference(startTime).inMilliseconds}ms');
    };
  }

  final controller = container.read(playbackControllerProvider);
  await SystemMediaSessionManager.initialize(controller);

  final accountService = container.read(ytAccountServiceProvider);
  await accountService.initialize();

  // If already logged in on startup, trigger background synchronization
  if (accountService.isLoggedIn) {
    container.read(ytmSyncManagerProvider.notifier).startSync();
  }

  final goRouter = container.read(goRouterProvider);
  // Handle session expiry by routing back to the welcome/login page
  container.read(sessionManagerProvider).onSessionExpired = () {
    goRouter.go('/welcome');
  };

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DAMusicApp(),
    ),
  );
}

class DAMusicApp extends ConsumerWidget {
  const DAMusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(dynamicThemeProvider);
    final goRouter = ref.watch(goRouterProvider);

    // Watch session login transitions to automatically trigger initial library sync
    ref.listen<SessionManager>(sessionManagerProvider, (previous, next) {
      if (next.isLoggedIn && !(previous?.isLoggedIn ?? false)) {
        ref.read(ytmSyncManagerProvider.notifier).startSync();
      }
    });

    return MaterialApp.router(
      title: 'DA Tunes',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      darkTheme: themeData,
      themeMode: ThemeMode.dark,
      routerConfig: goRouter,
      builder: (context, child) {
        return AnimatedTheme(
          data: themeData,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
