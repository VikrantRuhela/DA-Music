import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/theme/tokens.dart';
import '../../../../../shared/widgets/da_icon_button.dart';
import 'immersive_background.dart';
import 'vinyl_widget.dart';
import 'song_info.dart';
import 'progress_section.dart';
import 'playback_controls.dart';
import 'lyrics_section.dart';
import 'collapse_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/providers/player_providers.dart';
import '../../../../../shared/utils/song_options.dart';

class ImmersivePlayer extends ConsumerWidget {
  const ImmersivePlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);

    return ImmersiveBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DATokens.spacingLarge),
          child: Column(
            children: [
              // Top Right Actions Row (Collapse and More options)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DAIconButton(
                    icon: Icons.queue_music_outlined,
                    tooltip: 'Open Queue',
                    onPressed: () => context.push('/queue'),
                  ),
                  const SizedBox(width: DATokens.spacingSmall),
                  const CollapseButton(),
                  const SizedBox(width: DATokens.spacingSmall),
                  DAIconButton(
                    icon: Icons.more_vert_outlined,
                    tooltip: 'More Options',
                    onPressed: currentSong != null
                        ? () => showSongOptionsMenu(context, ref, currentSong)
                        : () {},
                  ),
                ],
              ),

              // Main Centered Content (Vinyl, Metadata, Controls)
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const VinylWidget(),
                        const SizedBox(height: DATokens.spacingLarge + 8.0),
                        SongInfo(
                          title: currentSong?.title ?? 'No Track Selected',
                          artist: currentSong?.artist ?? 'Choose a track to play',
                          album: currentSong?.album ?? '',
                        ),
                        const SizedBox(height: DATokens.spacingMedium),
                        const ProgressSection(),
                        const SizedBox(height: DATokens.spacingMedium),
                        const PlaybackControls(),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: DATokens.spacingLarge),

              // Bottom Lyrics Preview Box
              const LyricsSection(),
            ],
          ),
        ),
      ),
    );
  }
}
