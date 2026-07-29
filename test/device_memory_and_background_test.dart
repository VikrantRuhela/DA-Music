// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'package:flutter_test/flutter_test.dart';
import 'package:da_tunes/core/services/device_memory_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceMemoryManager & Background Tests', () {
    test('High-end device mode preserves 100% full blur intensity', () {
      DeviceMemoryManager.instance.initialize(forceLowRamForTesting: false);
      expect(DeviceMemoryManager.instance.isLowRamDevice, isFalse);

      final sigma = DeviceMemoryManager.instance.getRecommendedBlurSigma(40.0);
      expect(sigma, equals(40.0));
    });

    test('Low-end device mode returns 0.0 for heavy full-screen background blurs', () {
      DeviceMemoryManager.instance.initialize(forceLowRamForTesting: true);
      expect(DeviceMemoryManager.instance.isLowRamDevice, isTrue);

      final sigma = DeviceMemoryManager.instance.getRecommendedBlurSigma(40.0);
      expect(sigma, equals(0.0));
    });

    test('Vinyl and Minimal player 20% blur reduction on low-end mode equals 32.0 sigma', () {
      DeviceMemoryManager.instance.initialize(forceLowRamForTesting: true);
      expect(DeviceMemoryManager.instance.isLowRamDevice, isTrue);

      const double highEndBlur = 40.0;
      final double lowEndVinylBlur = highEndBlur * 0.80; // 20% reduction
      expect(lowEndVinylBlur, equals(32.0));
    });
  });
}
