import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../app/theme/tokens.dart';
import '../../../../../shared/widgets/da_icon_button.dart';
import 'immersive_background.dart';
import '../vinyl_player_widget.dart';
import 'song_info.dart';
import 'progress_section.dart';
import 'playback_controls.dart';
import 'lyrics_section.dart';
import 'collapse_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/providers/player_providers.dart';
import '../../../../../shared/providers/library_providers.dart';
import '../../../../../shared/models/playback_state.dart';
import '../../../../../shared/utils/song_options.dart';

class ImmersivePlayer extends ConsumerWidget {
  const ImmersivePlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final libraryManager = ref.watch(libraryManagerProvider);
    final isLiked = currentSong != null && libraryManager.isSongLiked(currentSong.id);

    const Widget leftTurntableSide = VinylPlayerWidget();

    final Widget rightControlsSide = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SongInfo(
          title: currentSong?.title ?? 'No Track Selected',
          artist: currentSong?.artist ?? 'Choose a track to play',
          album: currentSong?.album ?? '',
        ),
        const SizedBox(height: DATokens.spacingSmall),
        const _ImmersiveActionRow(),
        const SizedBox(height: DATokens.spacingSmall),
        const ProgressSection(),
        const SizedBox(height: DATokens.spacingSmall),
        const PlaybackControls(),
        const SizedBox(height: DATokens.spacingMedium),
        const LyricsSection(),
      ],
    );

    return ImmersiveBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DATokens.spacingLarge,
            vertical: DATokens.spacingMedium,
          ),
          child: Column(
            children: [
              // Top Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DAIconButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.redAccent : null,
                    tooltip: isLiked ? 'Remove from Favorites' : 'Add to Favorites',
                    onPressed: currentSong != null
                        ? () => ref.read(libraryManagerProvider.notifier).toggleLikeSong(currentSong)
                        : () {},
                  ),
                  const SizedBox(width: DATokens.spacingSmall),
                  DAIconButton(
                    icon: Icons.more_vert_outlined,
                    tooltip: 'More Options',
                    onPressed: currentSong != null
                        ? () => showSongOptionsMenu(context, ref, currentSong)
                        : () {},
                  ),
                  const SizedBox(width: DATokens.spacingSmall),
                  const CollapseButton(),
                ],
              ),

              // Responsive content layout based on window width
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 850) {
                      // Desktop/Landscape side-by-side view
                      return Row(
                        children: [
                          const Expanded(
                            flex: 11,
                            child: leftTurntableSide,
                          ),
                          const SizedBox(width: DATokens.spacingLarge),
                          Expanded(
                            flex: 10,
                            child: SingleChildScrollView(
                              child: rightControlsSide,
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Compact/Portrait vertical view
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: DATokens.spacingMedium),
                            leftTurntableSide,
                            const SizedBox(height: DATokens.spacingMedium),
                            rightControlsSide,
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImmersiveActionRow extends ConsumerWidget {
  const _ImmersiveActionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daColors;
    final currentSong = ref.watch(currentSongProvider);
    final libraryManager = ref.watch(libraryManagerProvider);
    final isLiked = currentSong != null && libraryManager.isSongLiked(currentSong.id);

    return Container(
      constraints: const BoxConstraints(maxWidth: 480.0),
      padding: const EdgeInsets.symmetric(horizontal: DATokens.spacingLarge),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.queue_music_outlined),
            color: colors.textSecondary,
            iconSize: 24.0,
            tooltip: 'Queue',
            onPressed: () => context.push('/queue'),
          ),
          const _AudioVisualizer(),
          IconButton(
            icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
            color: isLiked ? Colors.redAccent : colors.textSecondary,
            iconSize: 24.0,
            tooltip: isLiked ? 'Remove from Favorites' : 'Add to Favorites',
            onPressed: currentSong != null
                ? () => ref.read(libraryManagerProvider.notifier).toggleLikeSong(currentSong)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz_outlined),
            color: colors.textSecondary,
            iconSize: 24.0,
            tooltip: 'Options',
            onPressed: currentSong != null
                ? () => showSongOptionsMenu(context, ref, currentSong)
                : null,
          ),
        ],
      ),
    );
  }
}

class _AudioVisualizer extends ConsumerStatefulWidget {
  const _AudioVisualizer();

  @override
  ConsumerState<_AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends ConsumerState<_AudioVisualizer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<double> _heights = List.filled(7, 2.0);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateHeights);
    _controller.repeat();
  }

  void _updateHeights() {
    final playbackState = ref.read(playbackStateProvider);
    final isPlaying = playbackState.status == PlaybackStatus.playing;

    setState(() {
      for (int i = 0; i < _heights.length; i++) {
        if (isPlaying) {
          _heights[i] = 4.0 + _random.nextDouble() * 18.0;
        } else {
          _heights[i] = _heights[i] * 0.8 + 0.4;
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateHeights);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;

    return Container(
      height: 36.0,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_heights.length, (index) {
          return Container(
            width: 3.0,
            height: _heights[index],
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }
}
