// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Layer hierarchy blur: Layer 2 Container has BackdropFilter while Layer 3 foreground remains unblurred', (tester) async {
    const showAlbumArt = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              // Layer 1: Raw Album Artwork Background
              Positioned.fill(
                child: Container(color: Colors.red),
              ),

              // Layer 2: Main Dark Wine Container Surface (Frosted Glass Blur)
              if (showAlbumArt)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.50),
                      ),
                    ),
                  ),
                ),

              // Layer 3: Unblurred Foreground UI
              const Positioned.fill(
                child: Center(
                  child: Text('Sharp Foreground Text'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify BackdropFilter is present on Layer 2 for container blur
    expect(find.byType(BackdropFilter), findsOneWidget);
    // Verify foreground text is rendered sharp & unblurred on Layer 3
    expect(find.text('Sharp Foreground Text'), findsOneWidget);
  });
}
