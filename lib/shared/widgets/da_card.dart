import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/extensions/context_extensions.dart';
import '../../app/theme/tokens.dart';
import '../animations/motion_system.dart';

class DACard extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isHoverable;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const DACard({
    super.key,
    required this.child,
    this.onTap,
    this.isHoverable = true,
    this.width,
    this.height,
    this.padding,
  });

  @override
  ConsumerState<DACard> createState() => _DACardState();
}

class _DACardState extends ConsumerState<DACard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final scaleMode = ref.watch(motionScaleModeProvider);

    final double scale = (widget.isHoverable && _isHovered && scaleMode != MotionScaleMode.disabled)
        ? 1.02
        : 1.0;

    final shadow = widget.isHoverable && _isHovered
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16.0,
              offset: const Offset(0, 8),
            )
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8.0,
              offset: const Offset(0, 4),
            )
          ];

    final duration = ref.scaledDuration(DAMotion.veryFast);
    final curve = ref.scaledCurve(DAMotion.easeOut);

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (widget.isHoverable) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (widget.isHoverable) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: duration,
          curve: curve,
          child: AnimatedContainer(
            duration: duration,
            curve: curve,
            width: widget.width,
            height: widget.height,
            padding: widget.padding ?? const EdgeInsets.all(DATokens.spacingMedium),
            decoration: BoxDecoration(
              color: _isHovered && widget.isHoverable
                  ? colors.surfaceHover
                  : colors.surfaceCard,
              borderRadius: BorderRadius.circular(DATokens.radiusLarge),
              border: Border.all(
                color: colors.border,
                width: 1.0,
              ),
              boxShadow: shadow,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
