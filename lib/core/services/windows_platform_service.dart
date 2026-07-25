import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_service.dart';
import '../../shared/models/music_models.dart';
import '../../shared/models/playback_state.dart';

class WindowsPlatformService extends WindowListener implements PlatformService {
  static const String _prefWidth = 'window_width';
  static const String _prefHeight = 'window_height';
  static const String _prefX = 'window_x';
  static const String _prefY = 'window_y';
  static const String _prefMaximized = 'window_maximized';

  static Future<void> Function()? onShutdown;

  bool _isInitialized = false;
  SharedPreferences? _prefs;
  Timer? _debounceTimer;

  @override
  Future<void> initializeWindow() async {
    if (_isInitialized) return;
    debugPrint(' [Windows Platform] Initializing Windows integration layer...');

    windowManager.addListener(this);
    await windowManager.ensureInitialized();

    // Cache SharedPreferences instance during initialization to avoid blocking calls on shutdown
    _prefs = await SharedPreferences.getInstance();

    // Configure frameless window custom frame
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
    await windowManager.setPreventClose(true);

    // Load and restore previous session window states
    await restoreWindowState();

    _isInitialized = true;
  }

  @override
  Future<void> saveWindowState() async {
    try {
      final isMinimized = await windowManager.isMinimized();
      if (isMinimized) return;

      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;

      final isMaximized = await windowManager.isMaximized();
      await prefs.setBool(_prefMaximized, isMaximized);

      if (!isMaximized) {
        final size = await windowManager.getSize();
        final position = await windowManager.getPosition();

        if (position.dx < -10000 || position.dy < -10000 || size.width <= 100 || size.height <= 100) {
          return;
        }

        await prefs.setDouble(_prefWidth, size.width);
        await prefs.setDouble(_prefHeight, size.height);
        await prefs.setDouble(_prefX, position.dx);
        await prefs.setDouble(_prefY, position.dy);
      }
      debugPrint(' [Windows Platform] Saved window layout state.');
    } catch (e) {
      debugPrint(' [Windows Platform] Failed to save window state: $e');
    }
  }

  @override
  Future<void> restoreWindowState() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;

      final double? width = prefs.getDouble(_prefWidth);
      final double? height = prefs.getDouble(_prefHeight);
      final double? x = prefs.getDouble(_prefX);
      final double? y = prefs.getDouble(_prefY);
      final bool? isMaximized = prefs.getBool(_prefMaximized);

      if (width != null && width > 100 && height != null && height > 100) {
        await windowManager.setSize(Size(width, height));
      } else {
        await windowManager.setSize(const Size(1280, 720));
      }

      if (x != null && x > -10000 && y != null && y > -10000) {
        await windowManager.setPosition(Offset(x, y));
      } else {
        await windowManager.center();
      }

      if (isMaximized == true) {
        await windowManager.maximize();
      }

      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      debugPrint(' [Windows Platform] Failed to restore window state: $e');
      await windowManager.setSize(const Size(1280, 720));
      await windowManager.center();
      await windowManager.show();
    }
  }

  @override
  Future<void> updateSmtc(Song song, PlaybackStatus status, Duration position) async {
    debugPrint(' [Windows Platform SMTC] Updating SMTC Media Session:');
    debugPrint('   - Track: ${song.title} by ${song.artist}');
    debugPrint('   - Status: ${status.name} at position: ${position.inSeconds}s');
  }

  @override
  Future<void> showNotification(String title, String body) async {
    debugPrint(' [Windows Platform Toast] Displaying Native Toast: "$title" - $body');
  }

  @override
  Future<void> setupSystemTray() async {
    debugPrint(' [Windows Platform Tray] Setting up System Tray menu...');
  }

  void _debouncedSaveWindowState() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      saveWindowState();
    });
  }

  @override
  void onWindowClose() async {
    debugPrint(' [Windows Platform] Intercepted close event, executing clean shutdown...');
    final startTime = DateTime.now();

    // Cancel any pending debounce writes
    _debounceTimer?.cancel();

    // 1. Save final window layout state directly
    final saveTime = DateTime.now();
    await saveWindowState();
    debugPrint(' [Windows Platform] Window state saved in ${DateTime.now().difference(saveTime).inMilliseconds}ms');

    // 2. Execute registered shutdown callback with a safety timeout guard
    if (onShutdown != null) {
      final shutdownTime = DateTime.now();
      await onShutdown!().timeout(
        const Duration(milliseconds: 400),
        onTimeout: () => debugPrint(' [Windows Platform] Shutdown callback timed out'),
      );
      debugPrint(' [Windows Platform] Services shutdown completed in ${DateTime.now().difference(shutdownTime).inMilliseconds}ms');
    }

    // 3. Cleanup window manager listeners and destroy window
    windowManager.removeListener(this);
    await windowManager.destroy();

    debugPrint(' [Windows Platform] Window destroyed, terminating process. Total shutdown duration: ${DateTime.now().difference(startTime).inMilliseconds}ms');
    
    // 4. Hard terminate process to ensure all native background threads are killed
    exit(0);
  }

  @override
  void onWindowResized() {
    _debouncedSaveWindowState();
  }

  @override
  void onWindowMoved() {
    _debouncedSaveWindowState();
  }

  @override
  Future<void> dispose() async {
    _debounceTimer?.cancel();
    windowManager.removeListener(this);
    _isInitialized = false;
  }
}
