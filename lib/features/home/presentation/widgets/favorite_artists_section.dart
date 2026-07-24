import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'section_header.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../core/extensions/context_extensions.dart';

class FavoriteArtistsSection extends StatelessWidget {
  final List<String> artists;

  const FavoriteArtistsSection({
    super.key,
    required this.artists,
  });

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) return const SizedBox.shrink();

    final colors = context.daColors;
    final typography = context.daTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Your Favorite Artists'),
        SizedBox(
          height: 140.0,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artistName = artists[index];
              return Padding(
                padding: const EdgeInsets.only(right: DATokens.spacingMedium),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      context.go('/search?q=${Uri.encodeComponent(artistName)}');
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 80.0,
                          height: 80.0,
                          decoration: BoxDecoration(
                            color: colors.surfaceCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.border),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            artistName.isNotEmpty ? artistName[0].toUpperCase() : '?',
                            style: typography.title.copyWith(
                              fontSize: 28.0,
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: DATokens.spacingSmall),
                        SizedBox(
                          width: 90.0,
                          child: Text(
                            artistName,
                            style: typography.body.copyWith(fontSize: 12.0),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
