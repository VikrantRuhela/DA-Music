import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/providers/player_providers.dart';
import 'player_background.dart';
import 'player_header.dart';
import 'vinyl_player_widget.dart';
import 'song_information.dart';
import 'progress_section.dart';
import 'playback_controls.dart';
import 'lyrics_preview.dart';
import 'immersive/immersive_player.dart';

class PersistentPlayerPanel extends ConsumerWidget {
  const PersistentPlayerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isImmersive = ref.watch(immersiveModeProvider);
    final duration = isImmersive ? const Duration(milliseconds: 420) : const Duration(milliseconds: 380);

    final currentSong = ref.watch(currentSongProvider);

    return PlayerBackground(
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.fastOutSlowIn,
        switchOutCurve: Curves.fastOutSlowIn,
        child: isImmersive
            ? const ImmersivePlayer(key: ValueKey('immersive'))
            : Padding(
                key: const ValueKey('standard'),
                padding: const EdgeInsets.symmetric(
                  horizontal: DATokens.spacingMedium,
                  vertical: DATokens.spacingLarge,
                ),
                child: Column(
                  children: [
                    const PlayerHeader(),
                    const SizedBox(height: DATokens.spacingLarge),
                    const VinylPlayerWidget(),
                    const SizedBox(height: DATokens.spacingLarge),
                    SongInformation(
                      title: currentSong?.title ?? 'No Track Selected',
                      artist: currentSong?.artist ?? 'Choose a track to play',
                      album: currentSong?.album ?? '',
                    ),
                    const SizedBox(height: DATokens.spacingMedium),
                    const ProgressSection(),
                    const SizedBox(height: DATokens.spacingMedium),
                    const PlaybackControls(),
                    const SizedBox(height: DATokens.spacingLarge),
                    const LyricsPreview(),
                  ],
                ),
              ),
      ),
    );
  }
}
