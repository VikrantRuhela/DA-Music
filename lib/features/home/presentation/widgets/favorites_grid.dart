import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'album_card.dart';
import 'section_header.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../domain/entities/playlist.dart';

class FavoritesGrid extends StatelessWidget {
  final List<Playlist> playlists;

  const FavoritesGrid({
    super.key,
    required this.playlists,
  });

  @override
  Widget build(BuildContext context) {
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
