import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../app/theme/tokens.dart';
import '../../../../../shared/providers/player_providers.dart';

class ProgressSection extends ConsumerStatefulWidget {
  const ProgressSection({super.key});

  @override
  ConsumerState<ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends ConsumerState<ProgressSection> {
  double? _dragValue;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString();
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final typography = context.daTypography;
    final controller = ref.watch(playbackControllerProvider);
    final currentSong = ref.watch(currentSongProvider);

    final duration = currentSong?.duration ?? Duration.zero;
    final position = controller.position;

    final double progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final displayPosition = _dragValue != null
        ? Duration(milliseconds: (_dragValue! * duration.inMilliseconds).toInt())
        : position;

    return Container(
      constraints: const BoxConstraints(maxWidth: 480.0),
      padding: const EdgeInsets.symmetric(horizontal: DATokens.spacingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4.0,
              activeTrackColor: colors.primary,
              inactiveTrackColor: colors.border,
              thumbColor: colors.primary,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
            ),
            child: Slider(
              value: _dragValue ?? progress,
              onChanged: (val) {
                setState(() {
                  _dragValue = val;
                });
              },
              onChangeEnd: (val) {
                controller.seek(Duration(milliseconds: (val * duration.inMilliseconds).toInt()));
                setState(() {
                  _dragValue = null;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DATokens.spacingSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(displayPosition),
                  style: typography.caption.copyWith(color: colors.textSecondary),
                ),
                Text(
                  _formatDuration(duration),
                  style: typography.caption.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
