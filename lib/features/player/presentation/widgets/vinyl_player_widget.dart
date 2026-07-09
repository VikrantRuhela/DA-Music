import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/providers/player_providers.dart';
import '../../../../shared/models/playback_state.dart';

class VinylPlayerWidget extends ConsumerStatefulWidget {
  const VinylPlayerWidget({super.key});

  @override
  ConsumerState<VinylPlayerWidget> createState() => _VinylPlayerWidgetState();
}

class _VinylPlayerWidgetState extends ConsumerState<VinylPlayerWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final playbackState = ref.watch(playbackStateProvider);
    final isPlaying = playbackState.status == PlaybackStatus.playing;

    final currentSong = ref.watch(currentSongProvider);

    final glowShadow = _isHovered
        ? [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.35),
              blurRadius: 32.0,
              spreadRadius: 4.0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16.0,
              offset: const Offset(0, 8),
            )
          ]
        : [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.12),
              blurRadius: 20.0,
              spreadRadius: 1.0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16.0,
              offset: const Offset(0, 8),
            )
          ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: DATokens.durationFast,
        curve: DATokens.curveHover,
        width: 220.0,
        height: 220.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: glowShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Vinyl Plate & Grooves
            Container(
              width: 220.0,
              height: 220.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                border: Border.all(
                  color: colors.border,
                  width: 2.0,
                ),
                gradient: RadialGradient(
                  colors: [
                    Colors.black,
                    Colors.grey.shade900,
                    Colors.black,
                    Colors.grey.shade900,
                    Colors.black,
                  ],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
            ),

            // Multiple Groove Rings
            Container(
              width: 170.0,
              height: 170.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1.0,
                ),
              ),
            ),
            Container(
              width: 130.0,
              height: 130.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1.0,
                ),
              ),
            ),

            // Center Label
            _VinylCenterLabel(
              child: Container(
                width: 88.0,
                height: 88.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.15),
                  border: Border.all(
                    color: Colors.black,
                    width: 4.0,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: currentSong?.artworkUrl != null && currentSong!.artworkUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          currentSong.artworkUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildDefaultCenter(colors),
                        ),
                      )
                    : _buildDefaultCenter(colors),
              ),
            ),

            // Spindle Hole
            Container(
              width: 10.0,
              height: 10.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
            ),
          ],
        )
            .animate(
              target: isPlaying ? 1.0 : 0.0,
              onPlay: (animController) => animController.repeat(),
            )
            .rotate(
              duration: const Duration(seconds: 12),
              curve: Curves.linear,
            ),
      ),
    );
  }

  Widget _buildDefaultCenter(dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.album_outlined,
            size: DATokens.iconLarge,
            color: colors.primary,
          ),
          const SizedBox(height: 2.0),
          Text(
            'DA',
            style: context.daTypography.caption.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 10.0,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _VinylCenterLabel extends StatelessWidget {
  final Widget child;

  const _VinylCenterLabel({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
