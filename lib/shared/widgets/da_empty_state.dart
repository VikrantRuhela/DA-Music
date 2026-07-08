import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../../app/theme/tokens.dart';

class DAEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  const DAEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final typography = context.daTypography;

    return Padding(
      padding: const EdgeInsets.all(DATokens.spacingXLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: DATokens.iconXLarge,
            color: colors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: DATokens.spacingMedium),
          Text(
            title,
            style: typography.title.copyWith(color: colors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DATokens.spacingSmall),
          Text(
            description,
            style: typography.body.copyWith(
              color: colors.textSecondary.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: DATokens.spacingLarge),
            action!,
          ],
        ],
      ),
    );
  }
}
