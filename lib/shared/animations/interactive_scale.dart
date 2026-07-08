import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'motion_system.dart';

class InteractiveScale extends ConsumerStatefulWidget {
  final Widget child;
  final double hoverScale;
  final double pressScale;
  final VoidCallback? onTap;
  final MouseCursor cursor;

  const InteractiveScale({
    super.key,
    required this.child,
    this.hoverScale = 1.02,
    this.pressScale = 0.96,
    this.onTap,
    this.cursor = SystemMouseCursors.click,
  });

  @override
  ConsumerState<InteractiveScale> createState() => _InteractiveScaleState();
}

class _InteractiveScaleState extends ConsumerState<InteractiveScale> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final scaleMode = ref.watch(motionScaleModeProvider);

    if (scaleMode == MotionScaleMode.disabled) {
      return GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: widget.onTap != null ? widget.cursor : MouseCursor.defer,
          child: widget.child,
        ),
      );
    }

    double scale = 1.0;
    if (_isPressed) {
      scale = widget.pressScale;
    } else if (_isHovered) {
      scale = widget.hoverScale;
    }

    final duration = ref.scaledDuration(
      _isPressed ? DAMotion.fast : DAMotion.veryFast,
    );
    final curve = ref.scaledCurve(DAMotion.easeOut);

    Widget result = AnimatedScale(
      scale: scale,
      duration: duration,
      curve: curve,
      child: widget.child,
    );

    if (widget.onTap != null) {
      result = GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: result,
      );
    }

    return MouseRegion(
      cursor: widget.onTap != null ? widget.cursor : MouseCursor.defer,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: result,
    );
  }
}
