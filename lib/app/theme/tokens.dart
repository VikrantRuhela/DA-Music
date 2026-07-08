import 'package:flutter/widgets.dart';

/// Design Tokens for DA Music.
/// These constants define the visual rules for colors, radius, typography,
/// padding, icon sizes, animation durations, and curves.
class DATokens {
  DATokens._();

  // Color Palette - Sleek Premium Dark Theme
  static const Color darkBackground = Color(0xFF08080A);
  static const Color darkSurface = Color(0xFF0F0F13);
  static const Color darkSurfaceCard = Color(0xFF16161C);
  static const Color darkSurfaceHover = Color(0xFF1F1F28);
  static const Color darkPrimary = Color(0xFF10B981); // Vibrant Emerald Green
  static const Color darkAccent = Color(0xFF6366F1); // Indigo Highlight
  static const Color darkTextPrimary = Color(0xFFF3F4F6); // Slate 100
  static const Color darkTextSecondary = Color(0xFF9CA3AF); // Slate 400
  static const Color darkBorder = Color(0xFF27273F);

  // Color Palette - Premium Light Theme (Optional readiness)
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF3F4F6);
  static const Color lightSurfaceHover = Color(0xFFE5E7EB);
  static const Color lightPrimary = Color(0xFF059669);
  static const Color lightAccent = Color(0xFF4F46E5);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightBorder = Color(0xFFE5E7EB);

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
