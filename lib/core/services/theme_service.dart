import '../../domain/entities/value_objects.dart';

abstract class ThemeService {
  Future<void> setAccentColor(ThemeColor color);
  Future<void> toggleDarkMode(bool enabled);
}
