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

  bool _isInitialized = false;

  @override
  Future<void> initializeWindow() async {
    if (_isInitialized) return;
    debugPrint(' [Windows Platform] Initializing Windows integration layer...');

    windowManager.addListener(this);
    await windowManager.ensureInitialized();

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
      final prefs = await SharedPreferences.getInstance();

      final isMaximized = await windowManager.isMaximized();
      await prefs.setBool(_prefMaximized, isMaximized);

      if (!isMaximized) {
        final size = await windowManager.getSize();
        final position = await windowManager.getPosition();

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
      final prefs = await SharedPreferences.getInstance();

      final double? width = prefs.getDouble(_prefWidth);
      final double? height = prefs.getDouble(_prefHeight);
      final double? x = prefs.getDouble(_prefX);
      final double? y = prefs.getDouble(_prefY);
      final bool? isMaximized = prefs.getBool(_prefMaximized);

      if (width != null && height != null) {
        await windowManager.setSize(Size(width, height));
      } else {
        await windowManager.setSize(const Size(1280, 720));
      }

      if (x != null && y != null) {
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

  @override
  void onWindowClose() async {
    debugPrint(' [Windows Platform] Intercepted close event, saving state and exiting...');
    await saveWindowState();
    windowManager.removeListener(this);
    await windowManager.destroy();
  }

  @override
  void onWindowResized() {
    saveWindowState();
  }

  @override
  void onWindowMoved() {
    saveWindowState();
  }

  @override
  Future<void> dispose() async {
    windowManager.removeListener(this);
    _isInitialized = false;
  }
}
