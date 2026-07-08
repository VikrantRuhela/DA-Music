import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../app/theme/tokens.dart';
import '../../../../../shared/providers/player_providers.dart';
import '../../../../../shared/providers/library_providers.dart';
import '../../../../../shared/utils/artist_navigation.dart';

class SongInfo extends ConsumerWidget {
  final String title;
  final String artist;
  final String album;

  const SongInfo({
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
      padding: const EdgeInsets.symmetric(horizontal: DATokens.spacingLarge),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Balanced spacer to keep title/artist perfectly centered
          const SizedBox(width: 32.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: typography.display.copyWith(
                    fontSize: 26.0,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: DATokens.spacingSmall),
                GestureDetector(
                  onTap: () => navigateToArtistByName(context, ref, artist),
                  child: Text(
                    artist,
                    style: typography.headline.copyWith(
                      fontSize: 16.0,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.normal,
                      decoration: TextDecoration.underline,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  album,
                  style: typography.body.copyWith(
                    fontSize: 13.0,
                    color: colors.textSecondary.withValues(alpha: 0.5),
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
              color: isLiked ? Colors.redAccent : Colors.white70,
            ),
            iconSize: 32.0,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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
