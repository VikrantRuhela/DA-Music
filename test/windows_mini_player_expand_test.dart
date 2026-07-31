// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:da_tunes/app/theme/theme.dart';
import 'package:da_tunes/shared/providers/player_providers.dart';
import 'package:da_tunes/features/player/presentation/widgets/expand_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Windows Immersive Player & Expand Behavior Tests', () {
    testWidgets('ExpandButton renders and toggles immersiveModeProvider state', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: DATheme.darkTheme,
            home: const Scaffold(
              body: Center(
                child: ExpandButton(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ExpandButton), findsOneWidget);
      expect(container.read(immersiveModeProvider), isFalse);

      container.read(immersiveModeProvider.notifier).state = true;
      await tester.pump();

      expect(container.read(immersiveModeProvider), isTrue);
    });
  });
}
