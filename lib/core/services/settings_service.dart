import '../../../shared/models/music_models.dart';

abstract class SettingsService {
  Future<PlayerSettings> loadSettings();
  Future<void> saveSettings(PlayerSettings settings);
}
