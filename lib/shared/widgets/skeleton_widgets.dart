import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';
import '../../core/extensions/context_extensions.dart';

class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = DATokens.radiusMedium,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.border.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonAlbumCard extends StatelessWidget {
  const SkeletonAlbumCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: SkeletonContainer(
            width: double.infinity,
            height: double.infinity,
            borderRadius: DATokens.radiusXLarge,
          ),
        ),
        SizedBox(height: DATokens.spacingSmall),
        SkeletonContainer(width: 80.0, height: 14.0),
        SizedBox(height: 4.0),
        SkeletonContainer(width: 50.0, height: 11.0),
      ],
    );
  }
}

class SkeletonSongRow extends StatelessWidget {
  const SkeletonSongRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: DATokens.spacingTiny + 2.0),
      child: Row(
        children: [
          SkeletonContainer(
            width: 40.0,
            height: 40.0,
            borderRadius: DATokens.radiusMedium,
          ),
          SizedBox(width: DATokens.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonContainer(width: 120.0, height: 14.0),
                SizedBox(height: 4.0),
                SkeletonContainer(width: 80.0, height: 11.0),
              ],
            ),
          ),
          SkeletonContainer(width: 32.0, height: 12.0),
        ],
      ),
    );
  }
}

class SkeletonHeader extends StatelessWidget {
  const SkeletonHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: DATokens.spacingMedium),
      child: SkeletonContainer(width: 140.0, height: 20.0),
    );
  }
}
