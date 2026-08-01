import 'package:flutter/material.dart';
import '../../../../shared/widgets/da_card.dart';
import '../../../../shared/widgets/da_image.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/utils/metadata_formatter.dart';

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
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceHover,
                borderRadius: BorderRadius.circular(DATokens.radiusMedium),
              ),
              clipBehavior: Clip.antiAlias,
              child: DAImage(
                url: artworkUrl,
                fit: BoxFit.cover,
                placeholder: _buildPlaceholder(colors),
              ),
            ),
          ),
          const SizedBox(height: DATokens.spacingSmall + 2),
          Text(
            title,
            style: typography.title.copyWith(fontSize: 14.0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2.0),
          Text(
            MetadataFormatter.formatArtist(subtitle),
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
