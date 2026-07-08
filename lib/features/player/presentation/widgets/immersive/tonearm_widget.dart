import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/providers/player_providers.dart';
import '../../../../../shared/models/playback_state.dart';

class TonearmWidget extends ConsumerStatefulWidget {
  const TonearmWidget({super.key});

  @override
  ConsumerState<TonearmWidget> createState() => _TonearmWidgetState();
}

class _TonearmWidgetState extends ConsumerState<TonearmWidget> {
  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final currentSong = ref.watch(currentSongProvider);
    final playbackState = ref.watch(playbackStateProvider);
    final controller = ref.watch(playbackControllerProvider);

    final duration = currentSong?.duration ?? Duration.zero;
    final position = controller.position;
    final double progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final isPlayingOrPaused = currentSong != null &&
        (playbackState.status == PlaybackStatus.playing ||
            playbackState.status == PlaybackStatus.paused);

    // REST: -4 degrees, PLAY: 22 (start) to 42 (end) degrees
    final double targetAngle = isPlayingOrPaused
        ? (22.0 + progress * 20.0) * (pi / 180.0)
        : -4.0 * (pi / 180.0);

    // Lift goes from 0.0 (landed on record) to 1.0 (raised on holder)
    final double targetLift = isPlayingOrPaused ? 0.0 : 1.0;

    return IgnorePointer(
      child: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: -4.0 * (pi / 180.0), end: targetAngle),
            duration: Duration(milliseconds: isPlayingOrPaused ? 800 : 1000),
            curve: Curves.easeInOutCubic,
            builder: (context, angle, child) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1.0, end: targetLift),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                builder: (context, lift, child) {
                  return CustomPaint(
                    size: const Size(460.0, 380.0),
                    painter: _TonearmPainter(
                      angle: angle,
                      lift: lift,
                      primaryColor: colors.primary,
                      accentColor: colors.accent,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TonearmPainter extends CustomPainter {
  final double angle;
  final double lift;
  final Color primaryColor;
  final Color accentColor;

  _TonearmPainter({
    required this.angle,
    required this.lift,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Pivot Base Center point (completely outside the record circle)
    const double pivotX = 380.0;
    const double pivotY = 90.0;

    // 1. Draw Pivot Base Shadow (stationary)
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawCircle(const Offset(pivotX, pivotY + 4.0), 24.0, shadowPaint);

    // 2. Draw Pivot Base circular housing
    final Paint basePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.grey.shade700,
          Colors.grey.shade900,
          Colors.grey.shade800,
          Colors.grey.shade600,
        ],
      ).createShader(Rect.fromCircle(center: const Offset(pivotX, pivotY), radius: 24.0));
    canvas.drawCircle(const Offset(pivotX, pivotY), 24.0, basePaint);

    final Paint innerBasePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.grey.shade400,
          Colors.grey.shade800,
          Colors.grey.shade500,
        ],
      ).createShader(Rect.fromCircle(center: const Offset(pivotX, pivotY), radius: 14.0));
    canvas.drawCircle(const Offset(pivotX, pivotY), 14.0, innerBasePaint);

    // 3. Draw Tonearm Body (rotates around pivot)
    canvas.save();
    canvas.translate(pivotX, pivotY);
    canvas.rotate(angle);

    // Lift scale & offset for 3D raised height effect
    final double armScale = 1.0 + 0.03 * lift;
    final double shadowOffset = 6.0 + 8.0 * lift;
    final double shadowBlur = 8.0 + 6.0 * lift;
    canvas.scale(armScale);

    // Rigid arm length = 250px. Tube curves down-left, ends at headshell (e.g. at -93, 231 when straight, curved path maps relative)
    // S-arm tube: starts at (0, 0), curves down-left, ends at (X=-93, Y=231)
    final Path armPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(0, 80, -60, 120, -93, 231);

    // Draw Tonearm Shadow (rotates & translates dynamically with lift height)
    final Paint armShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur);
    
    canvas.save();
    canvas.translate(shadowOffset * 0.7, shadowOffset);
    canvas.drawPath(armPath, armShadowPaint);
    // Draw counterweight shadow
    canvas.drawRect(Rect.fromCenter(center: const Offset(0, -28), width: 14, height: 20), Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur));
    canvas.restore();

    // Draw Silver Metallic Tonearm Tube
    final Paint tubePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey.shade400,
          Colors.grey.shade200,
          Colors.grey.shade600,
          Colors.grey.shade400,
        ],
      ).createShader(const Rect.fromLTWH(-93, 0, 93, 231));
    canvas.drawPath(armPath, tubePaint);

    final Paint tubeHighlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawPath(armPath, tubeHighlightPaint);

    // 4. Counterweight (back stub, opposite side of pivot center)
    final Paint weightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.grey.shade900,
          Colors.grey.shade700,
          Colors.grey.shade900,
        ],
      ).createShader(const Rect.fromLTWH(-7, -35, 14, 20));
    canvas.drawRect(Rect.fromCenter(center: const Offset(0, -25), width: 12, height: 16), weightPaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(0, -32), width: 16, height: 6), Paint()..color = Colors.black);

    // 5. Headshell / Cartridge & Needle Stylus (at the end of tube: -93, 231)
    canvas.save();
    canvas.translate(-93, 231);
    canvas.rotate(-angle * 0.35); // Angled headshell offset

    // Cartridge plate
    final Paint headshellPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.grey.shade800,
          Colors.black,
        ],
      ).createShader(const Rect.fromLTWH(-8, 0, 16, 38));
    
    // Draw Cartridge / Headshell
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-8, 0, 16, 36), const Radius.circular(2.5)), headshellPaint);

    // Finger Lift (metallic pin on the right)
    final Paint fingerLiftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = Colors.grey.shade400;
    canvas.drawLine(const Offset(8, 10), const Offset(15, 12), fingerLiftPaint);
    canvas.drawLine(const Offset(15, 12), const Offset(16, 8), fingerLiftPaint);

    // Cartridge Brand Accent / Stylus (only this touches the record!)
    canvas.drawRect(const Rect.fromLTWH(-6, 26, 12, 6), Paint()..color = primaryColor);

    // Stylus Needle point
    canvas.drawCircle(const Offset(0, 32), 1.2, Paint()..color = Colors.white.withValues(alpha: 0.8));

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TonearmPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.lift != lift ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
