import 'platform_service.dart';
import '../../shared/models/music_models.dart';
import '../../shared/models/playback_state.dart';

/// Default platform fallback (e.g. for Android/mobile).
class DefaultPlatformService implements PlatformService {
  @override
  Future<void> initializeWindow() async {}

  @override
  Future<void> saveWindowState() async {}

  @override
  Future<void> restoreWindowState() async {}

  @override
  Future<void> updateSmtc(Song song, PlaybackStatus status, Duration position) async {}

  @override
  Future<void> showNotification(String title, String body) async {}

  @override
  Future<void> setupSystemTray() async {}

  @override
  Future<void> dispose() async {}
}
