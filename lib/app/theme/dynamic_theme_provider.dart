import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'theme.dart';
import '../../shared/providers/player_providers.dart';
import '../../shared/models/music_models.dart';

final dynamicThemeProvider = StateNotifierProvider<DynamicThemeNotifier, ThemeData>((ref) {
  final notifier = DynamicThemeNotifier();
  // Listen to current song changes to trigger palette extraction
  ref.listen<Song?>(currentSongProvider, (previous, next) {
    notifier.updatePalette(next);
  });
  return notifier;
});

class DynamicThemeNotifier extends StateNotifier<ThemeData> {
  static final Map<String, DAThemeExtension> _cache = {};

  DynamicThemeNotifier() : super(DATheme.darkTheme);

  Future<void> updatePalette(Song? song) async {
    if (song == null) {
      state = DATheme.darkTheme;
      return;
    }

    // Check cache first
    if (_cache.containsKey(song.id)) {
      state = _buildThemeData(_cache[song.id]!);
      return;
    }

    final String? artworkUrl = song.artworkUrl;
    if (artworkUrl == null || artworkUrl.isEmpty) {
      state = DATheme.darkTheme;
      return;
    }

    try {
      final ImageProvider imageProvider = NetworkImage(artworkUrl);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 16,
        timeout: const Duration(seconds: 4),
      );

      final Color dominantColor = paletteGenerator.dominantColor?.color ?? const Color(0xFF00E676);
      final Color vibrantColor = paletteGenerator.vibrantColor?.color ?? dominantColor;
      final Color mutedColor = paletteGenerator.mutedColor?.color ?? dominantColor;

      // Calibrate and adjust HSL saturation and lightness for clean premium dark theme compatibility
      final primaryHsl = HSLColor.fromColor(vibrantColor);
      final primaryColor = primaryHsl
          .withSaturation((primaryHsl.saturation).clamp(0.4, 0.8))
          .withLightness((primaryHsl.lightness).clamp(0.4, 0.65))
          .toColor();

      final accentHsl = HSLColor.fromColor(mutedColor);
      final accentColor = accentHsl
          .withSaturation((accentHsl.saturation).clamp(0.4, 0.8))
          .withLightness((accentHsl.lightness).clamp(0.4, 0.65))
          .toColor();

      // Extract a very dark, tinted background
      final bgHsl = HSLColor.fromColor(dominantColor);
      final backgroundColor = bgHsl
          .withSaturation((bgHsl.saturation * 0.15).clamp(0.0, 0.22))
          .withLightness(0.06) // Sleek dark value
          .toColor();

      // Extracted tinted surface values
      final surfaceColor = bgHsl
          .withSaturation((bgHsl.saturation * 0.15).clamp(0.0, 0.22))
          .withLightness(0.09)
          .toColor();

      final surfaceCardColor = bgHsl
          .withSaturation((bgHsl.saturation * 0.15).clamp(0.0, 0.22))
          .withLightness(0.12)
          .toColor();

      final surfaceHoverColor = bgHsl
          .withSaturation((bgHsl.saturation * 0.15).clamp(0.0, 0.22))
          .withLightness(0.16)
          .toColor();

      final borderColor = bgHsl
          .withSaturation((bgHsl.saturation * 0.15).clamp(0.0, 0.22))
          .withLightness(0.20)
          .toColor();

      final customExtension = DAThemeExtension(
        background: backgroundColor,
        surface: surfaceColor,
        surfaceCard: surfaceCardColor,
        surfaceHover: surfaceHoverColor,
        primary: primaryColor,
        accent: accentColor,
        textPrimary: Colors.white,
        textSecondary: Colors.white70,
        border: borderColor,
        typography: DATypography.dark,
      );

      // Cache it
      _cache[song.id] = customExtension;

      state = _buildThemeData(customExtension);
    } catch (e) {
      dev.log('DynamicTheme: Palette extraction failed: $e');
      // If load fails, keep the current state or default to darkTheme
      if (state == DATheme.darkTheme) {
        state = DATheme.darkTheme;
      }
    }
  }

  ThemeData _buildThemeData(DAThemeExtension extension) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: extension.background,
      colorScheme: ColorScheme.dark(
        primary: extension.primary,
        surface: extension.surface,
        onPrimary: Colors.white,
        onSurface: extension.textPrimary,
        error: Colors.redAccent,
      ),
      extensions: [extension],
    );
  }
}
