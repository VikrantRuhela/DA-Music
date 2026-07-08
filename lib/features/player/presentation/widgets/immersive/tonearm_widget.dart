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

    // REST: -20 degrees, PLAY: 15 (start) to 38 (end) degrees
    final double targetAngle = isPlayingOrPaused
        ? (15.0 + progress * 23.0) * (pi / 180.0)
        : -20.0 * (pi / 180.0);

    // Animate the lift based on playing state (lift is higher when moving, down when landed)
    final double targetLift = isPlayingOrPaused ? 0.0 : 1.0;

    return IgnorePointer(
      child: Stack(
        children: [
          // Arm Angle Sweep Animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: -20.0 * (pi / 180.0), end: targetAngle),
            duration: Duration(milliseconds: isPlayingOrPaused ? 1000 : 1200),
            curve: Curves.easeInOutCubic,
            builder: (context, angle, child) {
              // Lift Animation
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1.0, end: targetLift),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                builder: (context, lift, child) {
                  return CustomPaint(
                    size: const Size(400.0, 400.0),
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
  final double lift; // 0.0 (down on vinyl) to 1.0 (raised on holder)
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
    // Pivot Base Center point (top-right of turntable area)
    const double pivotX = 300.0;
    const double pivotY = 70.0;

    // 1. Draw Pivot Base Shadow (stationary)
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawCircle(const Offset(pivotX, pivotY + 4.0), 30.0, shadowPaint);

    // 2. Draw Pivot Base (metallic rings)
    final Paint basePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.grey.shade700,
          Colors.grey.shade900,
          Colors.grey.shade800,
          Colors.grey.shade600,
        ],
      ).createShader(Rect.fromCircle(center: const Offset(pivotX, pivotY), radius: 30.0));
    canvas.drawCircle(const Offset(pivotX, pivotY), 30.0, basePaint);

    final Paint innerBasePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.grey.shade400,
          Colors.grey.shade800,
          Colors.grey.shade500,
        ],
      ).createShader(Rect.fromCircle(center: const Offset(pivotX, pivotY), radius: 18.0));
    canvas.drawCircle(const Offset(pivotX, pivotY), 18.0, innerBasePaint);

    // 3. Draw Tonearm Body (rotates around pivot)
    canvas.save();
    canvas.translate(pivotX, pivotY);
    canvas.rotate(angle);

    // The scale & offset for 3D lifting effect
    final double armScale = 1.0 + 0.04 * lift;
    final double shadowOffset = 8.0 + 10.0 * lift;
    final double shadowBlur = 10.0 + 8.0 * lift;
    canvas.scale(armScale);

    // Local coordinates for Tonearm tube path
    // Tube starts at pivot (0, 0), curves down-left, ends at headshell (e.g. at -110, 240)
    final Path armPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(0, 100, -80, 140, -110, 250);

    // Draw Tonearm Shadow (rotates & translates with lift)
    final Paint armShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur);
    
    // Shadow offset translation (down-right relative to arm)
    canvas.save();
    canvas.translate(shadowOffset * 0.7, shadowOffset);
    canvas.drawPath(armPath, armShadowPaint);
    // Draw counterweight shadow
    canvas.drawRect(Rect.fromCenter(center: const Offset(0, -32), width: 18, height: 24), Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur));
    canvas.restore();

    // Draw Silver Metallic Tonearm Tube
    final Paint tubePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
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
      ).createShader(const Rect.fromLTWH(-110, 0, 110, 250));
    canvas.drawPath(armPath, tubePaint);

    // Highlight inside tube for metallic sheen
    final Paint tubeHighlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawPath(armPath, tubeHighlightPaint);

    // 4. Counterweight (back stub, opposite side of rotation)
    final Paint weightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.grey.shade900,
          Colors.grey.shade700,
          Colors.grey.shade900,
        ],
      ).createShader(const Rect.fromLTWH(-9, -40, 18, 24));
    canvas.drawRect(Rect.fromCenter(center: const Offset(0, -28), width: 16, height: 20), weightPaint);
    // Weight ring
    canvas.drawRect(Rect.fromCenter(center: const Offset(0, -35), width: 20, height: 8), Paint()..color = Colors.black);

    // 5. Headshell / Cartridge (at the end of tube: -110, 250)
    canvas.save();
    canvas.translate(-110, 250);
    canvas.rotate(-angle * 0.4); // Angled headshell offset

    // Cartridge plate
    final Paint headshellPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.grey.shade800,
          Colors.black,
        ],
      ).createShader(const Rect.fromLTWH(-10, 0, 20, 45));
    
    // Draw Cartridge / Headshell
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-9, 0, 18, 42), const Radius.circular(3.0)), headshellPaint);

    // Finger Lift (metallic pin on the right)
    final Paint fingerLiftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.grey.shade400;
    canvas.drawLine(const Offset(9, 12), const Offset(18, 14), fingerLiftPaint);
    canvas.drawLine(const Offset(18, 14), const Offset(19, 10), fingerLiftPaint);

    // Cartridge Brand Accent / Stylus
    canvas.drawRect(const Rect.fromLTWH(-7, 30, 14, 8), Paint()..color = primaryColor);

    // Tiny needle light dot (high premium detail!)
    canvas.drawCircle(const Offset(0, 36), 1.5, Paint()..color = Colors.white.withValues(alpha: 0.8));

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
