import 'dart:io';
import 'dart:async';
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
import 'shared/widgets/da_image.dart';
import 'package:path_provider/path_provider.dart';

import 'package:desktop_webview_window/desktop_webview_window.dart';

import 'core/services/device_memory_manager.dart';
import 'core/services/startup_tracker.dart';

class DnsCacheEntry {
  final List<InternetAddress> ipv6;
  final List<InternetAddress> ipv4;
  final DateTime expiresAt;

  DnsCacheEntry({required this.ipv6, required this.ipv4, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

final Map<String, DnsCacheEntry> _dnsCache = {};

Future<Socket> connectDualStack(String host, int port) async {
  // Fast path for loopback & local addresses - bypass DNS lookup completely
  if (host == 'localhost' || host == '127.0.0.1' || host == '::1' || host == '0.0.0.0') {
    return await Socket.connect(host, port).timeout(const Duration(seconds: 3));
  }

  try {
    List<InternetAddress> ipv6Addresses = [];
    List<InternetAddress> ipv4Addresses = [];

    final cached = _dnsCache[host];
    if (cached != null && !cached.isExpired) {
      ipv6Addresses = cached.ipv6;
      ipv4Addresses = cached.ipv4;
    } else {
      final ipv6Future = InternetAddress.lookup(host, type: InternetAddressType.IPv6)
          .timeout(const Duration(milliseconds: 1500))
          .catchError((_) => <InternetAddress>[]);
      final ipv4Future = InternetAddress.lookup(host, type: InternetAddressType.IPv4)
          .timeout(const Duration(milliseconds: 1500))
          .catchError((_) => <InternetAddress>[]);
      
      final results = await Future.wait([ipv6Future, ipv4Future]);
      ipv6Addresses = results[0];
      ipv4Addresses = results[1];

      if (ipv6Addresses.isNotEmpty || ipv4Addresses.isNotEmpty) {
        _dnsCache[host] = DnsCacheEntry(
          ipv6: ipv6Addresses,
          ipv4: ipv4Addresses,
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        );
      }
    }
    
    if (ipv6Addresses.isEmpty && ipv4Addresses.isEmpty) {
      return await Socket.connect(host, port).timeout(const Duration(seconds: 3));
    }
    
    if (ipv6Addresses.isEmpty) {
      return await Socket.connect(ipv4Addresses.first, port).timeout(const Duration(seconds: 3));
    }
    
    if (ipv4Addresses.isEmpty) {
      return await Socket.connect(ipv6Addresses.first, port).timeout(const Duration(seconds: 3));
    }
    
    final completer = Completer<Socket>();
    const totalAttempts = 2;
    int failures = 0;
    
    void tryConnect(InternetAddress addr) async {
      try {
        final socket = await Socket.connect(addr, port).timeout(const Duration(seconds: 3));
        if (!completer.isCompleted) {
          completer.complete(socket);
        } else {
          socket.destroy();
        }
      } catch (_) {
        failures++;
        if (failures >= totalAttempts && !completer.isCompleted) {
          completer.completeError(Exception('Dual stack connection racing failed for $host'));
        }
      }
    }

    tryConnect(ipv6Addresses.first);
    
    await Future.delayed(const Duration(milliseconds: 150));
    if (!completer.isCompleted) {
      tryConnect(ipv4Addresses.first);
    }
    
    return await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Dual stack connection timeout for $host'));
        }
        return Socket.connect(host, port).timeout(const Duration(seconds: 3));
      },
    );
  } catch (_) {
    return await Socket.connect(host, port).timeout(const Duration(seconds: 3));
  }
}

class FallbackHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory = (Uri url, String? proxyHost, int? proxyPort) async {
      final host = proxyHost ?? url.host;
      final port = proxyPort ?? (url.port != 0 ? url.port : (url.scheme == 'https' ? 443 : 80));
      
      // Fast path loopback bypass for local stream proxy & local image cache requests
      if (host == 'localhost' || host == '127.0.0.1' || host == '::1' || host == '0.0.0.0') {
        final socket = await Socket.connect(host, port).timeout(const Duration(seconds: 3));
        if (url.scheme.toLowerCase() == 'https') {
          final secureSocket = await SecureSocket.secure(socket, host: host);
          return ConnectionTask.fromSocket(Future.value(secureSocket), () {});
        }
        return ConnectionTask.fromSocket(Future.value(socket), () {});
      }

      final socket = await connectDualStack(host, port);

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
  final mainStep = StartupTracker.startStep('Total Application Launch');

  await StartupTracker.runStep('HTTP Overrides & Flutter Binding', () async {
    HttpOverrides.global = FallbackHttpOverrides();
    WidgetsFlutterBinding.ensureInitialized();
    DeviceMemoryManager.instance.initialize();
  });

  await StartupTracker.runStep('Cache & Documents Paths', () async {
    try {
      final tempDir = await getTemporaryDirectory();
      DAImage.cacheDirPath = tempDir.path;
      final docDir = await getApplicationDocumentsDirectory();
      DAImage.documentsDirPath = docDir.path;
    } catch (_) {}
  });

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    if (runWebViewTitleBarWidget(args)) {
      return;
    }
  }

  final PlatformService platformService = !kIsWeb && Platform.isWindows
      ? WindowsPlatformService()
      : DefaultPlatformService();

  await StartupTracker.runStep('Platform Window Initialization', () async {
    await platformService.initializeWindow();
  });

  final storageService = JsonStorageService();
  await StartupTracker.runStep('Local JsonStorage Initialization', () async {
    await storageService.init();
  });

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

  final goRouter = container.read(goRouterProvider);
  container.read(sessionManagerProvider).onSessionExpired = () {
    goRouter.go('/welcome');
  };

  // Trigger non-blocking background initialization of MediaSession, Account Service, and Sync
  unawaited(_performPostAppLaunchInitialization(container));

  StartupTracker.endStep(mainStep, success: true);
  StartupTracker.printSummary();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DAMusicApp(),
    ),
  );
}

Future<void> _performPostAppLaunchInitialization(ProviderContainer container) async {
  await StartupTracker.runStep('MediaSession & AudioService Binding', () async {
    try {
      final controller = container.read(playbackControllerProvider);
      await SystemMediaSessionManager.initialize(controller);
    } catch (e) {
      debugPrint(' [Startup] MediaSession initialization warning: $e');
    }
  });

  await StartupTracker.runStep('YouTube Music Account Session Restore', () async {
    try {
      final accountService = container.read(ytAccountServiceProvider);
      await accountService.initialize();

      if (accountService.isLoggedIn) {
        container.read(ytmSyncManagerProvider.notifier).startSync();
      }
    } catch (e) {
      debugPrint(' [Startup] Account service initialization warning: $e');
    }
  });
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
