import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/providers/player_providers.dart';
import '../../../../shared/providers/library_providers.dart';
import '../../../../shared/utils/artist_navigation.dart';

class SongInformation extends ConsumerWidget {
  final String title;
  final String artist;
  final String album;

  const SongInformation({
    super.key,
    required this.title,
    required this.artist,
    required this.album,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daColors;
    final typography = context.daTypography;
    final currentSong = ref.watch(currentSongProvider);
    final libraryManager = ref.watch(libraryManagerProvider);
    final isLiked = currentSong != null && libraryManager.isSongLiked(currentSong.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DATokens.spacingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Balanced spacer to keep title/artist perfectly centered
          const SizedBox(width: 48.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: typography.title.copyWith(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: DATokens.spacingTiny),
                GestureDetector(
                  onTap: () => navigateToArtistByName(context, ref, artist),
                  child: Text(
                    artist,
                    style: typography.body.copyWith(
                      color: colors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  album,
                  style: typography.caption.copyWith(
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.redAccent : colors.textSecondary,
            ),
            iconSize: 28.0,
            tooltip: isLiked ? 'Remove from Favorites' : 'Add to Favorites',
            onPressed: currentSong != null
                ? () => ref.read(libraryManagerProvider.notifier).toggleLikeSong(currentSong)
                : null,
          ),
        ],
      ),
    );
  }
}
