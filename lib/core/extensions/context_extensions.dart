import 'package:flutter/material.dart';
import '../../app/theme/theme.dart';

/// Context Extensions to easily access tokens, themes and custom typographies.
extension DAContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  /// Fetch custom design token colors
  DAThemeExtension get daColors {
    final ext = Theme.of(this).extension<DAThemeExtension>();
    assert(ext != null, 'DAThemeExtension was not found in Theme. Make sure you set theme in MaterialApp.');
    return ext!;
  }

  /// Fetch custom design typography
  DATypography get daTypography => daColors.typography;
}

extension ColorContrast on Color {
  Color get contrastingColor {
    return ThemeData.estimateBrightnessForColor(this) == Brightness.light
        ? const Color(0xFF1C0A0D)
        : const Color(0xFFFBF1F2);
  }

  Color get contrastingColorMuted {
    return ThemeData.estimateBrightnessForColor(this) == Brightness.light
        ? const Color(0xFF5E494C)
        : const Color(0xFFAFA2A5);
  }
}
