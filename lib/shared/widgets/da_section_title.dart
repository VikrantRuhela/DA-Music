import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';

class DASectionTitle extends StatelessWidget {
  final String title;

  const DASectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.daTypography;
    final colors = context.daColors;

    return Text(
      title,
      style: typography.headline.copyWith(
        color: colors.textPrimary,
      ),
    );
  }
}
