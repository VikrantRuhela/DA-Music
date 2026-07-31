// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'package:flutter_test/flutter_test.dart';
import 'package:da_tunes/core/services/startup_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Startup Timing Diagnostics Tests', () {
    test('StartupTracker records step timings and generates summary', () async {
      final step = StartupTracker.startStep('Test Step 1');
      await Future.delayed(const Duration(milliseconds: 10));
      StartupTracker.endStep(step, success: true);

      expect(StartupTracker.records, isNotEmpty);
      final record = StartupTracker.records.firstWhere((r) => r.name == 'Test Step 1');
      expect(record.isSuccess, isTrue);
      expect(record.durationMs, greaterThanOrEqualTo(5));

      // Verify printSummary executes without throwing errors
      expect(() => StartupTracker.printSummary(), returnsNormally);
    });

    test('StartupTracker.runStep executes and records async action', () async {
      final val = await StartupTracker.runStep('Test RunStep', () async {
        await Future.delayed(const Duration(milliseconds: 5));
        return 42;
      });

      expect(val, equals(42));
      final record = StartupTracker.records.firstWhere((r) => r.name == 'Test RunStep');
      expect(record.isSuccess, isTrue);
      expect(record.durationMs, greaterThanOrEqualTo(2));
    });
  });
}
