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

void main([List<String> args = const []]) async {
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
      title: 'DA Music',
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
