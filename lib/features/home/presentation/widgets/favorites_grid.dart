import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'album_card.dart';
import 'section_header.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../domain/entities/playlist.dart';

import '../../../../core/extensions/context_extensions.dart';

class FavoritesGrid extends StatelessWidget {
  final List<Playlist> playlists;

  const FavoritesGrid({
    super.key,
    required this.playlists,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final typography = context.daTypography;

    if (playlists.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Featured Playlists'),
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
                Icon(Icons.playlist_play, color: colors.textSecondary.withValues(alpha: 0.4), size: 48.0),
                const SizedBox(height: DATokens.spacingSmall),
                Text(
                  'No playlist recommendations yet.',
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
        const SectionHeader(title: 'Featured Playlists'),
        LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            int crossAxisCount = 2;
            if (width >= 800) {
              crossAxisCount = 4;
            } else if (width >= 500) {
              crossAxisCount = 3;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: DATokens.spacingMedium,
                mainAxisSpacing: DATokens.spacingMedium,
                childAspectRatio: 0.78,
              ),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];

                return AlbumCard(
                  title: playlist.title,
                  subtitle: 'Playlist • By ${playlist.owner}',
                  artworkUrl: playlist.cover.url,
                  onTap: () {
                    debugPrint('Tapped Playlist ID: ${playlist.id}, Title: ${playlist.title}');
                    context.push('/album/${playlist.id}');
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
