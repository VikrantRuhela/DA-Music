import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/extensions/context_extensions.dart';
import 'package:da_music/shared/providers/player_providers.dart';

class ImmersiveBackground extends ConsumerWidget {
  final Widget child;

  const ImmersiveBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daColors;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
          ref.read(immersiveModeProvider.notifier).state = false;
        }
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: colors.background,
        child: Stack(
          children: [
            // Radial Gradient Layer
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      colors.primary.withValues(alpha: 0.12),
                      colors.accent.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Ambient Glow Layer (Top-Center / Left)
            Positioned(
              top: -100.0,
              left: MediaQuery.of(context).size.width * 0.1,
              child: Container(
                width: 500.0,
                height: 500.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.08),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.08),
                      blurRadius: 150.0,
                      spreadRadius: 50.0,
                    ),
                  ],
                ),
              ),
            ),

            // Content Layer
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }
}
