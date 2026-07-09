import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:da_music/shared/providers/player_providers.dart';

class ImmersiveBackground extends ConsumerWidget {
  final Widget child;

  const ImmersiveBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
          ref.read(immersiveModeProvider.notifier).state = false;
        }
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}
