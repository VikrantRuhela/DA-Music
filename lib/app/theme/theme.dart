import 'package:flutter/material.dart';
import 'tokens.dart';

class DATypography {
  final TextStyle display;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle body;
  final TextStyle caption;

  const DATypography({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.caption,
  });

  static const DATypography dark = DATypography(
    display: TextStyle(
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: DATokens.darkTextPrimary,
      letterSpacing: -0.5,
    ),
    headline: TextStyle(
      fontSize: 22.0,
      fontWeight: FontWeight.bold,
      color: DATokens.darkTextPrimary,
      letterSpacing: -0.2,
    ),
    title: TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: DATokens.darkTextPrimary,
    ),
    body: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.normal,
      color: DATokens.darkTextSecondary,
    ),
    caption: TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.normal,
      color: DATokens.darkTextSecondary,
    ),
  );

  static const DATypography light = DATypography(
    display: TextStyle(
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: DATokens.lightTextPrimary,
      letterSpacing: -0.5,
    ),
    headline: TextStyle(
      fontSize: 22.0,
      fontWeight: FontWeight.bold,
      color: DATokens.lightTextPrimary,
      letterSpacing: -0.2,
    ),
    title: TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: DATokens.lightTextPrimary,
    ),
    body: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.normal,
      color: DATokens.lightTextSecondary,
    ),
    caption: TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.normal,
      color: DATokens.lightTextSecondary,
    ),
  );
}

class DAThemeExtension extends ThemeExtension<DAThemeExtension> {
  final Color background;
  final Color surface;
  final Color surfaceCard;
  final Color surfaceHover;
  final Color primary;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final DATypography typography;
  final Color gradientStart;
  final Color gradientMiddle;
  final Color gradientEnd;

  const DAThemeExtension({
    required this.background,
    required this.surface,
    required this.surfaceCard,
    required this.surfaceHover,
    required this.primary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.typography,
    required this.gradientStart,
    required this.gradientMiddle,
    required this.gradientEnd,
  });

  static const DAThemeExtension dark = DAThemeExtension(
    background: DATokens.darkBackground,
    surface: DATokens.darkSurface,
    surfaceCard: DATokens.darkSurfaceCard,
    surfaceHover: DATokens.darkSurfaceHover,
    primary: DATokens.darkPrimary,
    accent: DATokens.darkAccent,
    textPrimary: DATokens.darkTextPrimary,
    textSecondary: DATokens.darkTextSecondary,
    border: DATokens.darkBorder,
    typography: DATypography.dark,
    gradientStart: Color(0xFF160E0F),
    gradientMiddle: Color(0xFF0F0B0C),
    gradientEnd: Color(0xFF070505),
  );

  static const DAThemeExtension light = DAThemeExtension(
    background: DATokens.lightBackground,
    surface: DATokens.lightSurface,
    surfaceCard: DATokens.lightSurfaceCard,
    surfaceHover: DATokens.lightSurfaceHover,
    primary: DATokens.lightPrimary,
    accent: DATokens.lightAccent,
    textPrimary: DATokens.lightTextPrimary,
    textSecondary: DATokens.lightTextSecondary,
    border: DATokens.lightBorder,
    typography: DATypography.light,
    gradientStart: Color(0xFFF9F6F6),
    gradientMiddle: Color(0xFFECE6E6),
    gradientEnd: Color(0xFFDFD4D4),
  );

  @override
  DAThemeExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceCard,
    Color? surfaceHover,
    Color? primary,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    DATypography? typography,
    Color? gradientStart,
    Color? gradientMiddle,
    Color? gradientEnd,
  }) {
    return DAThemeExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      typography: typography ?? this.typography,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientMiddle: gradientMiddle ?? this.gradientMiddle,
      gradientEnd: gradientEnd ?? this.gradientEnd,
    );
  }

  @override
  DAThemeExtension lerp(ThemeExtension<DAThemeExtension>? other, double t) {
    if (other is! DAThemeExtension) return this;
    return DAThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      typography: typography,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientMiddle: Color.lerp(gradientMiddle, other.gradientMiddle, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
    );
  }
}

class DATheme {
  DATheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DATokens.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: DATokens.darkPrimary,
        surface: DATokens.darkSurface,
        onPrimary: Colors.white,
        onSurface: DATokens.darkTextPrimary,
        error: Colors.redAccent,
      ),
      extensions: const [DAThemeExtension.dark],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: DATokens.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: DATokens.lightPrimary,
        surface: DATokens.lightSurface,
        onPrimary: Colors.white,
        onSurface: DATokens.lightTextPrimary,
        error: Colors.redAccent,
      ),
      extensions: const [DAThemeExtension.light],
    );
  }
}
