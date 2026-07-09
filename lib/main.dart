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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final PlatformService platformService = !kIsWeb && Platform.isWindows
      ? WindowsPlatformService()
      : DefaultPlatformService();

  await platformService.initializeWindow();

  final storageService = JsonStorageService();
  await storageService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const DAMusicApp(),
    ),
  );
}

class DAMusicApp extends ConsumerWidget {
  const DAMusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(dynamicThemeProvider);

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
