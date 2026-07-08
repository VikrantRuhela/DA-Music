import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MotionScaleMode { normal, reduced, disabled }

final motionScaleModeProvider = StateProvider<MotionScaleMode>((ref) => MotionScaleMode.normal);

class DAMotion {
  DAMotion._();

  // Durations
  static const Duration veryFast = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration large = Duration(milliseconds: 420);
  static const Duration extraLarge = Duration(milliseconds: 600);

  // Curves
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve spring = Cubic(0.175, 0.885, 0.32, 1.1); // Gentle spring overshoot

  // Scale duration based on mode
  static Duration getDuration(WidgetRef ref, Duration baseDuration) {
    final mode = ref.watch(motionScaleModeProvider);
    switch (mode) {
      case MotionScaleMode.normal:
        return baseDuration;
      case MotionScaleMode.reduced:
        return Duration(milliseconds: (baseDuration.inMilliseconds * 0.5).toInt());
      case MotionScaleMode.disabled:
        return Duration.zero;
    }
  }

  // Scale curve based on mode
  static Curve getCurve(WidgetRef ref, Curve baseCurve) {
    final mode = ref.watch(motionScaleModeProvider);
    if (mode == MotionScaleMode.reduced || mode == MotionScaleMode.disabled) {
      return Curves.linear;
    }
    return baseCurve;
  }
}

extension WidgetRefMotion on WidgetRef {
  Duration scaledDuration(Duration baseDuration) => DAMotion.getDuration(this, baseDuration);
  Curve scaledCurve(Curve baseCurve) => DAMotion.getCurve(this, baseCurve);
}
