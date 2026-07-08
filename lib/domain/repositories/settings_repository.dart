import '../../../shared/models/music_models.dart';

abstract class SettingsRepository {
  Future<PlayerSettings> loadSettings();
  Future<void> saveSettings(PlayerSettings settings);
}
