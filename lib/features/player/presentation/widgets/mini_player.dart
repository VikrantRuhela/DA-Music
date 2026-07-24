import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/providers/player_providers.dart';
import '../../../../shared/models/playback_state.dart';
import '../../../../shared/animations/interactive_scale.dart';
import '../../../../shared/utils/song_options.dart';
import '../../../../shared/widgets/da_image.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daColors;
    final typography = context.daTypography;

    final currentSong = ref.watch(currentSongProvider);
    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final controller = ref.watch(playbackControllerProvider);
    final isPlaying = controller.status == PlaybackStatus.playing;

    final duration = currentSong.duration;
    final position = controller.position;
    final double progress = (duration.inMilliseconds > 0)
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return InteractiveScale(
      hoverScale: 1.01,
      pressScale: 0.98,
      onTap: () {
        ref.read(immersiveModeProvider.notifier).state = true;
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 0) {
              controller.previous();
            } else if (details.primaryVelocity! < 0) {
              controller.next();
            }
          }
        },
        child: Container(
          height: 64.0,
          margin: const EdgeInsets.symmetric(
            horizontal: DATokens.spacingMedium,
            vertical: DATokens.spacingSmall,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceCard.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(DATokens.radiusLarge),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.2),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DATokens.radiusLarge),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DATokens.spacingMedium),
                      child: Row(
                        children: [
                          Container(
                            width: 40.0,
                            height: 40.0,
                            decoration: BoxDecoration(
                              color: colors.surfaceHover,
                              borderRadius: BorderRadius.circular(DATokens.radiusMedium),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: DAImage(
                              url: currentSong.artworkUrl,
                              fit: BoxFit.cover,
                              placeholder: Icon(Icons.music_note, color: colors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: DATokens.spacingMedium),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong.title,
                                  style: typography.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  currentSong.artist,
                                  style: typography.caption.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: colors.textPrimary,
                              size: 28.0,
                            ),
                            onPressed: () {
                              if (isPlaying) {
                                controller.pause();
                              } else {
                                controller.resume();
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.skip_next,
                              color: colors.textPrimary,
                              size: 24.0,
                            ),
                            onPressed: () {
                              controller.next();
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: colors.textSecondary,
                              size: 24.0,
                            ),
                            onPressed: () {
                              showSongOptionsMenu(context, ref, currentSong);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 3.0,
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: colors.border.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
