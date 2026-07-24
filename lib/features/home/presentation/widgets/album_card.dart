import 'package:flutter/material.dart';
import '../../../../shared/widgets/da_card.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../app/theme/tokens.dart';

class AlbumCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? artworkUrl;
  final VoidCallback? onTap;

  const AlbumCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.artworkUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final typography = context.daTypography;

    return DACard(
      onTap: onTap,
      padding: const EdgeInsets.all(DATokens.spacingSmall + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album artwork container
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceHover,
                borderRadius: BorderRadius.circular(DATokens.radiusMedium),
              ),
              clipBehavior: Clip.antiAlias,
              child: artworkUrl != null && artworkUrl!.isNotEmpty
                  ? Image.network(
                      artworkUrl!,
                      fit: BoxFit.cover,
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: child,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(colors),
                    )
                  : _buildPlaceholder(colors),
            ),
          ),
          const SizedBox(height: DATokens.spacingSmall + 2),
          // Title
          Text(
            title,
            style: typography.title.copyWith(fontSize: 14.0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2.0),
          // Subtitle
          Text(
            subtitle,
            style: typography.body.copyWith(
              fontSize: 12.0,
              color: colors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(dynamic colors) {
    return Center(
      child: Icon(
        Icons.album_outlined,
        size: DATokens.iconXLarge,
        color: colors.textSecondary.withOpacity(0.3),
      ),
    );
  }
}
