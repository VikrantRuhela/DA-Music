import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';

class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;

    return Stack(
      children: [
        // Base dark wine/black gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.background,
                Colors.black,
              ],
            ),
          ),
        ),

        // Layer 2: Primary accent blurred blob (top-left/center-left)
        Positioned(
          left: -150,
          top: -150,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colors.primary.withValues(alpha: 0.15),
                  colors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Layer 3: Secondary accent blurred blob (bottom-right)
        Positioned(
          right: -200,
          bottom: -100,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colors.accent.withValues(alpha: 0.12),
                  colors.accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Layer 4: Vignette overlay
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.4,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.65),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),

        // Content
        Positioned.fill(child: child),
      ],
    );
  }
}
