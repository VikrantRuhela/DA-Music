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
