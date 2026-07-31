// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:da_tunes/app/theme/theme.dart';
import 'package:da_tunes/app/theme/tokens.dart';
import 'package:da_tunes/app/theme/dynamic_theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Monochrome Theme & Dynamic Adaptation Tests', () {
    test('Default Dark Theme is pure monochrome when no song is playing', () {
      final theme = DATheme.darkTheme;
      final extension = theme.extension<DAThemeExtension>();

      expect(extension, isNotNull);
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFF000000))); // Pure Black Background
      expect(extension!.background, equals(const Color(0xFF000000)));
      expect(extension.surface, equals(const Color(0xFF121212))); // Near Black Surface
      expect(extension.primary, equals(const Color(0xFFFFFFFF))); // Pure White Primary
      expect(extension.textPrimary, equals(const Color(0xFFFFFFFF))); // White Text
      expect(extension.textSecondary, equals(const Color(0xFFAAAAAA))); // Gray Text
      expect(extension.border, equals(const Color(0xFF262626)));
    });

    test('Default Light Theme is pure monochrome when no song is playing', () {
      final theme = DATheme.lightTheme;
      final extension = theme.extension<DAThemeExtension>();

      expect(extension, isNotNull);
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFFFFFFFF))); // Pure White Background
      expect(extension!.background, equals(const Color(0xFFFFFFFF)));
      expect(extension.surface, equals(const Color(0xFFF5F5F5))); // Light Gray Surface
      expect(extension.primary, equals(const Color(0xFF000000))); // Pure Black Primary
      expect(extension.textPrimary, equals(const Color(0xFF000000))); // Black Text
      expect(extension.textSecondary, equals(const Color(0xFF666666))); // Dark Gray Text
    });

    test('DynamicThemeNotifier initializes with monochrome dark theme when song is null', () {
      final notifier = DynamicThemeNotifier();
      final currentTheme = notifier.state;
      final extension = currentTheme.extension<DAThemeExtension>();

      expect(currentTheme.scaffoldBackgroundColor, equals(const Color(0xFF000000)));
      expect(extension!.primary, equals(const Color(0xFFFFFFFF)));
      expect(extension.textSecondary, equals(const Color(0xFFAAAAAA)));
    });
  });
}
