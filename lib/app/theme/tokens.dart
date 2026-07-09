import 'package:flutter/widgets.dart';

/// Design Tokens for DA Music.
/// These constants define the visual rules for colors, radius, typography,
/// padding, icon sizes, animation durations, and curves.
class DATokens {
  DATokens._();

  // Color Palette - Sleek Premium Dark Theme (Maroon / Wine Aesthetic)
  static const Color darkBackground = Color(0xFF0C0708); // Very Dark Wine Background
  static const Color darkSurface = Color(0xFF140D0E);
  static const Color darkSurfaceCard = Color(0xFF1A1113);
  static const Color darkSurfaceHover = Color(0xFF23171A);
  static const Color darkPrimary = Color(0xFF8A1538); // Deep Wine / Burgundy Accent
  static const Color darkAccent = Color(0xFF6E182D); // Dark Maroon Highlight
  static const Color darkTextPrimary = Color(0xFFFBF1F2); // Tinted Slate
  static const Color darkTextSecondary = Color(0xFFAFA2A5); // Tinted Muted Slate
  static const Color darkBorder = Color(0xFF332024);

  // Color Palette - Premium Light Theme (Wine Aesthetic)
  static const Color lightBackground = Color(0xFFFDF8F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF8EEF0);
  static const Color lightSurfaceHover = Color(0xFFF0DFE2);
  static const Color lightPrimary = Color(0xFF8A1538);
  static const Color lightAccent = Color(0xFF6E182D);
  static const Color lightTextPrimary = Color(0xFF1C0A0D);
  static const Color lightTextSecondary = Color(0xFF5E494C);
  static const Color lightBorder = Color(0xFFEFE0E2);

  // Border Radius Tokens
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusXXLarge = 24.0;
  static const double radiusCircular = 999.0;

  // Spacing & Padding Tokens
  static const double spacingTiny = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // Icon Size Tokens
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // Animation Duration Tokens
  static const Duration durationFast = Duration(milliseconds: 120); // Hover states
  static const Duration durationMedium = Duration(milliseconds: 180); // Click states
  static const Duration durationSlow = Duration(milliseconds: 250); // Section transitions
  static const Duration durationStandard = Duration(milliseconds: 300);

  // Curve Tokens
  static const Curve curveSmooth = Curves.easeInOutCubic;
  static const Curve curveDecelerate = Curves.easeOutCubic;
  static const Curve curveHover = Curves.easeOutCubic;
}
