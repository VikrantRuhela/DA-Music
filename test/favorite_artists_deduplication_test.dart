// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:da_tunes/features/home/presentation/widgets/favorite_artists_section.dart';
import 'package:da_tunes/features/home/presentation/widgets/section_header.dart';
import 'package:da_tunes/app/theme/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createWidgetUnderTest(List<String> artists) {
    return MaterialApp(
      theme: DATheme.darkTheme,
      home: Scaffold(
        body: FavoriteArtistsSection(artists: artists),
      ),
    );
  }

  group('FavoriteArtistsSection Deduplication Tests', () {
    testWidgets('renders exactly ONE SectionHeader when artists list is non-empty', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(['Karan Aujla', 'Diljit Dosanjh']));

      expect(find.byType(SectionHeader), findsOneWidget);
      expect(find.text('Your Favorite Artists'), findsOneWidget);
      expect(find.text('Karan Aujla'), findsOneWidget);
      expect(find.text('Diljit Dosanjh'), findsOneWidget);
    });

    testWidgets('renders ZERO SectionHeaders when artists list is empty', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest([]));

      expect(find.byType(SectionHeader), findsNothing);
      expect(find.text('Your Favorite Artists'), findsNothing);
    });
  });
}
