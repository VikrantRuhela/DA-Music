// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:da_tunes/core/services/device_memory_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceMemoryManager Tests', () {
    test('Low RAM mode sets restricted ImageCache bounds', () {
      DeviceMemoryManager.instance.initialize(forceLowRamForTesting: true);
      expect(DeviceMemoryManager.instance.isLowRamDevice, isTrue);

      final imageCache = PaintingBinding.instance.imageCache;
      expect(imageCache.maximumSizeBytes, equals(30 * 1024 * 1024));
      expect(imageCache.maximumSize, equals(40));

      final downscaledWidth = DeviceMemoryManager.instance.getTargetCacheDimension(100.0, devicePixelRatio: 2.0);
      expect(downscaledWidth, equals(200));

      final recommendedBlur = DeviceMemoryManager.instance.getRecommendedBlurSigma(40.0);
      expect(recommendedBlur, equals(0.0));
    });

    test('High-end mode sets expanded ImageCache bounds', () {
      DeviceMemoryManager.instance.initialize(forceLowRamForTesting: false);
      expect(DeviceMemoryManager.instance.isLowRamDevice, isFalse);

      final imageCache = PaintingBinding.instance.imageCache;
      expect(imageCache.maximumSizeBytes, equals(120 * 1024 * 1024));
      expect(imageCache.maximumSize, equals(200));

      final recommendedBlur = DeviceMemoryManager.instance.getRecommendedBlurSigma(40.0);
      expect(recommendedBlur, equals(40.0));
    });
  });
}
