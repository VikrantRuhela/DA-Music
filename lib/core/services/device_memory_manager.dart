// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Centralized manager for detecting low-memory device conditions (<= 4GB RAM)
/// and tuning runtime parameters (ImageCache bounds, image downscaling, UI blur intensity).
class DeviceMemoryManager {
  static final DeviceMemoryManager instance = DeviceMemoryManager._internal();
  DeviceMemoryManager._internal();

  bool _isInitialized = false;
  bool _isLowRamDevice = false;

  bool get isLowRamDevice => _isLowRamDevice;

  /// Initialize memory bounds and detect device capabilities.
  void initialize({bool? forceLowRamForTesting}) {
    if (_isInitialized && forceLowRamForTesting == null) return;
    _isInitialized = true;

    if (forceLowRamForTesting != null) {
      _isLowRamDevice = forceLowRamForTesting;
    } else {
      _isLowRamDevice = _detectLowRamCondition();
    }

    _configureImageCache();
  }

  bool _detectLowRamCondition() {
    if (kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        final file = File('/proc/meminfo');
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          final match = RegExp(r'MemTotal:\s+(\d+)\s+kB').firstMatch(content);
          if (match != null) {
            final totalKb = int.parse(match.group(1)!);
            final totalGb = totalKb / (1024 * 1024);
            // Flag as low-RAM device ONLY if total RAM <= 4.2 GB (4GB RAM tier)
            return totalGb <= 4.2;
          }
        }
      }
    } catch (_) {}

    return false;
  }

  void _configureImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;

    if (_isLowRamDevice) {
      // 4GB RAM target: Limit ImageCache to 30 MB / 40 images max to prevent OOM
      imageCache.maximumSizeBytes = 30 * 1024 * 1024;
      imageCache.maximumSize = 40;
    } else {
      // High-end target: 120 MB / 200 images
      imageCache.maximumSizeBytes = 120 * 1024 * 1024;
      imageCache.maximumSize = 200;
    }
  }

  /// Trims image cache under memory pressure
  void clearMemoryCaches() {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}
  }

  /// Calculate optimal cacheWidth for image decoding based on target display width
  int getTargetCacheDimension(double? displayDimension, {int defaultSize = 400, double devicePixelRatio = 2.0}) {
    if (displayDimension == null || displayDimension <= 0) {
      return _isLowRamDevice ? defaultSize.clamp(100, 300) : defaultSize;
    }
    final target = (displayDimension * devicePixelRatio).round();
    if (_isLowRamDevice) {
      return target.clamp(60, 600);
    }
    return target.clamp(60, 1024);
  }

  /// Returns recommended BackdropFilter blur sigma based on device RAM tier.
  /// On high-end devices, returns 100% of standardSigma.
  /// On low-end devices, returns 0.0 for full-screen background blurs (replaced by adaptive color gradient extension)
  /// and low capped value for small UI overlays.
  double getRecommendedBlurSigma(double standardSigma) {
    if (_isLowRamDevice) {
      if (standardSigma >= 25.0) {
        return 0.0;
      }
      return (standardSigma * 0.2).clamp(0.0, 4.0);
    }
    return standardSigma;
  }
}
