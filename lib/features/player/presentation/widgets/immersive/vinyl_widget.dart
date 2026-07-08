import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../app/theme/tokens.dart';
import '../../../../../shared/providers/player_providers.dart';
import '../../../../../shared/models/playback_state.dart';

class VinylWidget extends ConsumerStatefulWidget {
  const VinylWidget({super.key});

  @override
  ConsumerState<VinylWidget> createState() => _VinylWidgetState();
}

class _VinylWidgetState extends ConsumerState<VinylWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _angle = 0.0;
  double _currentSpeed = 0.0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick);
    _controller.repeat();
  }

  void _tick() {
    final playbackState = ref.read(playbackStateProvider);
    final isPlaying = playbackState.status == PlaybackStatus.playing;
    final double targetSpeed = isPlaying ? 1.0 : 0.0;

    // Gradual acceleration (0.02) and deceleration (0.01)
    if (_currentSpeed < targetSpeed) {
      _currentSpeed = (_currentSpeed + 0.02).clamp(0.0, 1.0);
    } else if (_currentSpeed > targetSpeed) {
      _currentSpeed = (_currentSpeed - 0.01).clamp(0.0, 1.0);
    }

    if (_currentSpeed > 0.0) {
      setState(() {
        // Continuous rotation step
        _angle += 0.035 * _currentSpeed;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final currentSong = ref.watch(currentSongProvider);

    final glowShadow = _isHovered
        ? [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.25),
              blurRadius: 40.0,
              spreadRadius: 8.0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30.0,
              offset: const Offset(0, 15),
            )
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24.0,
              offset: const Offset(0, 12),
            )
          ];

    return Center(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: DATokens.durationFast,
          curve: DATokens.curveHover,
          width: 320.0,
          height: 320.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: glowShadow,
          ),
          child: Transform.rotate(
            angle: _angle,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Vinyl Platter with Radial Gradient (Reflections)
                Container(
                  width: 320.0,
                  height: 320.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF0D0D0D),
                        Color(0xFF262626),
                        Color(0xFF0D0D0D),
                        Color(0xFF1F1F1F),
                        Color(0xFF000000),
                      ],
                      stops: [0.0, 0.4, 0.65, 0.85, 1.0],
                    ),
                  ),
                ),

                // Vinyl Grooves Details
                for (double d in [280.0, 260.0, 240.0, 220.0, 200.0, 180.0, 160.0, 140.0])
                  Container(
                    width: d,
                    height: d,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.035),
                        width: 0.8,
                      ),
                    ),
                  ),

                // High-fidelity Gloss / Shine overlay (Semi-transparent conic reflection simulation)
                Container(
                  width: 320.0,
                  height: 320.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.06),
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.06),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),

                // Center Record Label (Album Artwork)
                Container(
                  width: 110.0,
                  height: 110.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.black,
                      width: 5.0,
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
            ),
          ),
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
            size: 40.0,
            color: colors.primary,
          ),
          const SizedBox(height: DATokens.spacingTiny),
          Text(
            'DA MUSIC',
            style: context.daTypography.caption.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 10.0,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
