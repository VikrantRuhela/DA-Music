import '../../shared/models/music_models.dart';
import '../../shared/models/playback_state.dart';

/// Abstract interface for platform-specific integration.
abstract class PlatformService {
  Future<void> initializeWindow();
  Future<void> saveWindowState();
  Future<void> restoreWindowState();
  Future<void> updateSmtc(Song song, PlaybackStatus status, Duration position);
  Future<void> showNotification(String title, String body);
  Future<void> setupSystemTray();
  Future<void> dispose();
}
