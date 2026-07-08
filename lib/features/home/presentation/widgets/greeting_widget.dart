import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../app/theme/tokens.dart';

class GreetingWidget extends StatelessWidget {
  const GreetingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final typography = context.daTypography;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: DATokens.spacingLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back, Voyager',
            style: typography.display.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: DATokens.spacingTiny),
          Text(
            'Ready to explore the soundscapes today?',
            style: typography.body.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
