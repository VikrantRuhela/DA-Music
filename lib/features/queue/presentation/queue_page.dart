import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/providers/player_providers.dart';
import '../../../shared/widgets/da_empty_state.dart';
import '../../../shared/utils/song_options.dart';
import '../../../shared/models/music_models.dart';
import '../../../shared/widgets/da_image.dart';

class QueuePage extends ConsumerWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daColors;
    final typography = context.daTypography;

    final controller = ref.watch(playbackControllerProvider);
    final queue = controller.currentQueue;
    final currentIndex = controller.currentIndex;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Play Queue',
          style: typography.title.copyWith(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
      ),
      body: queue.isEmpty
          ? const Center(
              child: DAEmptyState(
                icon: Icons.queue_music_outlined,
                title: 'Play Queue is Empty',
                description: 'Start playing songs to build a queue.',
              ),
            )
          : ReorderableListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: DATokens.spacingMedium,
                vertical: DATokens.spacingSmall,
              ),
              itemCount: queue.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final updatedSongs = List<Song>.from(queue);
                final song = updatedSongs.removeAt(oldIndex);
                updatedSongs.insert(newIndex, song);

                int newCurrentIndex = currentIndex;
                if (oldIndex == currentIndex) {
                  newCurrentIndex = newIndex;
                } else if (oldIndex < currentIndex && newIndex >= currentIndex) {
                  newCurrentIndex -= 1;
                } else if (oldIndex > currentIndex && newIndex <= currentIndex) {
                  newCurrentIndex += 1;
                }

                ref.read(playbackControllerProvider).reorderQueue(updatedSongs, newCurrentIndex);
              },
              itemBuilder: (context, index) {
                final song = queue[index];
                final isActive = index == currentIndex;

                return Card(
                  key: ValueKey(song.id),
                  color: isActive
                      ? colors.primary.withValues(alpha: 0.15)
                      : colors.surfaceCard.withValues(alpha: 0.1),
                  margin: const EdgeInsets.only(bottom: DATokens.spacingSmall),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DATokens.radiusMedium),
                    side: isActive
                        ? BorderSide(color: colors.primary, width: 1.0)
                        : BorderSide(color: colors.border.withValues(alpha: 0.1)),
                  ),
                  child: ListTile(
                    onTap: () {
                      ref.read(playbackControllerProvider).setQueue(
                            queue,
                            startIndex: index,
                            autoPlay: true,
                          );
                    },
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(DATokens.radiusSmall),
                      child: DAImage(
                        url: song.artworkUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: const Icon(Icons.music_note, color: Colors.white24),
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: typography.title.copyWith(
                        fontSize: 14.0,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? colors.primary : colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song.artist,
                      style: typography.caption.copyWith(color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive) ...[
                          Icon(Icons.volume_up, color: colors.primary),
                          const SizedBox(width: DATokens.spacingSmall),
                        ],
                        IconButton(
                          icon: Icon(Icons.more_vert, color: colors.textSecondary),
                          onPressed: () {
                            showSongOptionsMenu(context, ref, song);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
