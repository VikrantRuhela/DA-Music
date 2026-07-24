import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'album_card.dart';
import 'section_header.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../domain/entities/album.dart';

import '../../../../core/extensions/context_extensions.dart';

class RecommendedSection extends StatelessWidget {
  final List<Album> albums;

  const RecommendedSection({
    super.key,
    required this.albums,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final typography = context.daTypography;

    if (albums.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Recommended Albums'),
          Container(
            height: 150.0,
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(DATokens.radiusLarge),
              border: Border.all(color: colors.border),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.album_outlined, color: colors.textSecondary.withValues(alpha: 0.4), size: 48.0),
                const SizedBox(height: DATokens.spacingSmall),
                Text(
                  'No album recommendations yet.',
                  style: typography.body.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recommended Albums'),
        SizedBox(
          height: 230.0,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return Padding(
                padding: const EdgeInsets.only(right: DATokens.spacingMedium),
                child: SizedBox(
                  width: 160.0,
                  child: AlbumCard(
                    title: album.title,
                    subtitle: album.artistId,
                    artworkUrl: album.cover.url,
                    onTap: () {
                      debugPrint('Tapped Album ID: ${album.id}, Title: ${album.title}');
                      context.push('/album/${album.id}');
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
