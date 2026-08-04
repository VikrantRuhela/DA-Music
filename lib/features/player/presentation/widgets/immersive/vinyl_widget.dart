import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../app/theme/tokens.dart';
import '../../../../../shared/providers/player_providers.dart';
import '../../../../../shared/models/playback_state.dart';
import '../../../../../shared/widgets/da_image.dart';

class VinylWidget extends ConsumerStatefulWidget {
  const VinylWidget({super.key});

  @override
  ConsumerState<VinylWidget> createState() => _VinylWidgetState();
}

class _VinylWidgetState extends ConsumerState<VinylWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ValueNotifier<double> _angleNotifier = ValueNotifier<double>(0.0);
  double _currentSpeed = 0.0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick);
  }

  void _tick() {
    final playbackState = ref.read(playbackStateProvider);
    final isPlaying = playbackState.status == PlaybackStatus.playing;
    final double targetSpeed = isPlaying ? 1.0 : 0.0;

    if (_currentSpeed < targetSpeed) {
      _currentSpeed = (_currentSpeed + 0.02).clamp(0.0, 1.0);
    } else if (_currentSpeed > targetSpeed) {
      _currentSpeed = (_currentSpeed - 0.01).clamp(0.0, 1.0);
    }

    if (_currentSpeed > 0.0) {
      _angleNotifier.value += 0.035 * _currentSpeed;
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    _angleNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final currentSong = ref.watch(currentSongProvider);
    final playbackState = ref.watch(playbackStateProvider);
    final isPlaying = playbackState.status == PlaybackStatus.playing;

    if (isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    }

    final glowShadow = _isHovered
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 36.0,
              offset: const Offset(0, 15),
            )
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24.0,
              offset: const Offset(0, 12),
            )
          ];

    return Center(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: RepaintBoundary(
          child: AnimatedContainer(
            duration: DATokens.durationFast,
            curve: DATokens.curveHover,
            width: 320.0,
            height: 320.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: glowShadow,
            ),
            child: AnimatedBuilder(
              animation: _angleNotifier,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _angleNotifier.value,
                  child: child,
                );
              },
              child: _VinylDisc(
                artworkUrl: currentSong?.artworkUrl,
                colors: colors,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VinylDisc extends StatelessWidget {
  final String? artworkUrl;
  final dynamic colors;

  const _VinylDisc({
    required this.artworkUrl,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
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
        for (double d in const [280.0, 260.0, 240.0, 220.0, 200.0, 180.0, 160.0, 140.0])
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
          child: ClipOval(
            child: DAImage(
              url: artworkUrl,
              fit: BoxFit.cover,
              placeholder: _buildDefaultCenter(context, colors),
            ),
          ),
        ),
        Container(
          width: 10.0,
          height: 10.0,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultCenter(BuildContext context, dynamic colors) {
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
            'DA TUNES',
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

