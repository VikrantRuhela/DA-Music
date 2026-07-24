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
import '../../../../shared/widgets/da_image.dart';
import '../../../../core/extensions/context_extensions.dart';

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
                    _buildArtworkWidget(context, ref, currentSong),
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

  Widget _buildArtworkWidget(BuildContext context, WidgetRef ref, dynamic currentSong) {
    final style = ref.watch(playerStyleProvider);
    final colors = context.daColors;

    switch (style) {
      case PlayerStyle.minimal:
        return SizedBox(
          height: 380.0,
          child: Center(
            child: Container(
              width: 260.0,
              height: 260.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15.0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: DAImage(
                  url: currentSong?.artworkUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      case PlayerStyle.immersive:
        return SizedBox(
          height: 380.0,
          child: Center(
            child: Container(
              width: 260.0,
              height: 260.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.35),
                    blurRadius: 25.0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.3,
                      colors: [Colors.white, Colors.transparent],
                      stops: [0.35, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: DAImage(
                    url: currentSong?.artworkUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        );
      case PlayerStyle.vinyl:
      default:
        return const VinylPlayerWidget();
    }
  }
}
