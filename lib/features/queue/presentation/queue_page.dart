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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(immersiveModeProvider.notifier).state = true;
        }
      },
      child: Scaffold(
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
                onReorder: (oldIdx, newIdx) {
                  final controller = ref.read(playbackControllerProvider);
                  final currIdx = controller.currentIndex;
                  final updatedSongs = List<Song>.from(queue);
                  final s = updatedSongs.removeAt(oldIdx);
                  if (newIdx > oldIdx) newIdx--;
                  updatedSongs.insert(newIdx, s);
                  final newCurrentIndex = (currIdx == oldIdx) ? newIdx : ((currIdx > oldIdx && currIdx <= newIdx) ? currIdx - 1 : ((currIdx < oldIdx && currIdx >= newIdx) ? currIdx + 1 : currIdx));
                  controller.reorderQueue(updatedSongs, newCurrentIndex);
                },
                itemBuilder: (context, index) {
                  final song = queue[index];
                  final isActive = index == currentIndex;

                  return Container(
                    key: ValueKey('queue_item_${song.id}_$index'),
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    decoration: BoxDecoration(
                      color: isActive
                          ? colors.primary.withValues(alpha: 0.15)
                          : colors.surfaceCard.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DATokens.radiusMedium),
                      border: isActive
                          ? Border.all(color: colors.primary, width: 1.0)
                          : Border.all(color: colors.border.withValues(alpha: 0.1), width: 1.0),
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
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        song.title,
                        style: typography.body.copyWith(
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
                              showSongOptionsMenu(context, ref, song, queueIndex: index);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
