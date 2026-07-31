import 'package:flutter/widgets.dart';

/// Design Tokens for DA Tunes.
/// These constants define the visual rules for colors, radius, typography,
/// padding, icon sizes, animation durations, and curves.
class DATokens {
  DATokens._();

  // Color Palette - Premium Default Monochrome Dark Theme
  static const Color darkBackground = Color(0xFF000000); // Pure Black
  static const Color darkSurface = Color(0xFF121212); // Near Black
  static const Color darkSurfaceCard = Color(0xFF181818);
  static const Color darkSurfaceHover = Color(0xFF242424);
  static const Color darkPrimary = Color(0xFFFFFFFF); // Pure White Controls / Accent
  static const Color darkAccent = Color(0xFFCCCCCC); // Off-White Highlight
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // White Primary Text
  static const Color darkTextSecondary = Color(0xFFAAAAAA); // Gray Secondary Text
  static const Color darkBorder = Color(0xFF262626);

  // Color Palette - Premium Default Monochrome Light Theme
  static const Color lightBackground = Color(0xFFFFFFFF); // Pure White
  static const Color lightSurface = Color(0xFFF5F5F5); // Light Gray
  static const Color lightSurfaceCard = Color(0xFFEBEBEB);
  static const Color lightSurfaceHover = Color(0xFFE0E0E0);
  static const Color lightPrimary = Color(0xFF000000); // Pure Black Controls / Accent
  static const Color lightAccent = Color(0xFF333333); // Dark Gray Highlight
  static const Color lightTextPrimary = Color(0xFF000000); // Black Primary Text
  static const Color lightTextSecondary = Color(0xFF666666); // Dark Gray Secondary Text
  static const Color lightBorder = Color(0xFFE0E0E0);

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
