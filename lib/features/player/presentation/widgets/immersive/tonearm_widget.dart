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
  double? _dragAngle;
  bool _dragLocked = false;

  void _handleDrag(Offset localPos) {
    final currentSong = ref.read(currentSongProvider);
    if (currentSong == null) return;

    const double pivotX = 380.0;
    const double pivotY = 90.0;

    // Calculate relative vector from fixed pivot
    final double dx = pivotX - localPos.dx;
    final double dy = localPos.dy - pivotY;

    // Calculate angle in radians
    double draggedAngle = atan2(dx, dy);

    // Clamp to valid physical travel limit (0 to 45 degrees)
    draggedAngle = draggedAngle.clamp(0.0 * (pi / 180.0), 45.0 * (pi / 180.0));

    const double startAngle = 24.0 * (pi / 180.0);
    const double endAngle = 35.0 * (pi / 180.0);
    const double pausedAngle = 21.0 * (pi / 180.0);

    final controller = ref.read(playbackControllerProvider);
    final playbackState = ref.read(playbackStateProvider);

    if (_dragLocked) {
      // If locked in paused zone, only unlock if user drags back towards the record
      if (draggedAngle > 22.5 * (pi / 180.0)) {
        setState(() {
          _dragLocked = false;
          _dragAngle = draggedAngle;
        });
      }
      return;
    }

    if (draggedAngle < startAngle) {
      // Stylus leaves the record -> Pause immediately and lock to PAUSED position
      setState(() {
        _dragAngle = pausedAngle;
        _dragLocked = true;
      });
      if (playbackState.status == PlaybackStatus.playing) {
        controller.pause();
      }
    } else {
      // Dragging inside the playable grooves
      final double clampedAngle = draggedAngle.clamp(startAngle, endAngle);
      setState(() {
        _dragAngle = clampedAngle;
      });

      // Synchronize with playback position continuously
      final double progress = (clampedAngle - startAngle) / (endAngle - startAngle);
      final duration = currentSong.duration;
      if (duration.inMilliseconds > 0) {
        controller.seek(Duration(milliseconds: (progress * duration.inMilliseconds).toInt()));
      }

      // Automatically resume playback when entering groove area
      if (playbackState.status == PlaybackStatus.paused) {
        controller.play();
      }
    }
  }

  void _endDrag() {
    if (_dragAngle == null && !_dragLocked) return;

    const double startAngle = 24.0 * (pi / 180.0);
    const double endAngle = 35.0 * (pi / 180.0);
    final double finalAngle = _dragAngle ?? (21.0 * (pi / 180.0));

    final controller = ref.read(playbackControllerProvider);

    setState(() {
      _dragAngle = null;
      _dragLocked = false;
    });

    if (finalAngle >= startAngle && finalAngle <= endAngle) {
      // Released on record -> Resume playback
      controller.play();
    } else {
      // Released off record -> Pause and snap to PAUSED position
      controller.pause();
    }
  }

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

    final isPlaying = currentSong != null && playbackState.status == PlaybackStatus.playing;
    final isPaused = currentSong != null && playbackState.status == PlaybackStatus.paused;

    double targetAngle;
    double targetLift;

    if (_dragAngle != null || _dragLocked) {
      // Interactive dragging state
      targetAngle = _dragAngle ?? (21.0 * (pi / 180.0));
      targetLift = 0.8; // Hovering lift height
    } else if (isPlaying) {
      // Playback active -> follow progress strictly within grooves
      targetAngle = (24.0 + progress * 11.0) * (pi / 180.0);
      targetLift = 0.0; // Touch down on groove
    } else if (isPaused) {
      // Paused -> hover slightly lifted at the paused/current progress position
      final double currentProgressAngle = 24.0 + progress * 11.0;
      // Rotates slightly back (e.g. 3 degrees) and hovers
      targetAngle = (currentProgressAngle - 3.0).clamp(21.0, 35.0) * (pi / 180.0);
      targetLift = 0.75; // Raised slightly off record
    } else {
      // Stopped / rest holder
      targetAngle = 2.0 * (pi / 180.0);
      targetLift = 1.0; // Fully raised
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) => _handleDrag(details.localPosition),
      onPanUpdate: (details) => _handleDrag(details.localPosition),
      onPanEnd: (_) => _endDrag(),
      onPanCancel: () => _endDrag(),
      child: Stack(
        children: [
          // Smooth angle transition
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 2.0 * (pi / 180.0), end: targetAngle),
            duration: Duration(milliseconds: (_dragAngle != null && !_dragLocked) ? 40 : (isPlaying ? 800 : 1000)),
            curve: (_dragAngle != null && !_dragLocked) ? Curves.linear : Curves.easeInOutCubic,
            builder: (context, angle, child) {
              // Smooth lift transition
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1.0, end: targetLift),
                duration: const Duration(milliseconds: 400),
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
    // Fixed Pivot Center Point (Never moves)
    const double pivotX = 380.0;
    const double pivotY = 90.0;

    // 1. Draw Pivot Base Shadow (stationary)
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawCircle(const Offset(pivotX, pivotY + 4.0), 22.0, shadowPaint);

    // 2. Draw Pivot Base (metallic rings)
    final Paint basePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.grey.shade700,
          Colors.grey.shade900,
          Colors.grey.shade800,
          Colors.grey.shade600,
        ],
      ).createShader(Rect.fromCircle(center: const Offset(pivotX, pivotY), radius: 22.0));
    canvas.drawCircle(const Offset(pivotX, pivotY), 22.0, basePaint);

    final Paint innerBasePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.grey.shade400,
          Colors.grey.shade800,
          Colors.grey.shade500,
        ],
      ).createShader(Rect.fromCircle(center: const Offset(pivotX, pivotY), radius: 12.0));
    canvas.drawCircle(const Offset(pivotX, pivotY), 12.0, innerBasePaint);

    // 3. Draw Tonearm Body (rotates around pivot)
    canvas.save();
    canvas.translate(pivotX, pivotY);
    canvas.rotate(angle);

    // Shadow offset and blur scale dynamically with lift to represent 3D height,
    // but the rigid arm itself is NEVER scaled/stretched (Rule 1 & 7).
    final double shadowOffset = 3.5 + 8.5 * lift;
    final double shadowBlur = 4.0 + 8.0 * lift;

    // Rigid S-arm length = 230px. starts at (0, 0), curves down-left, ends at (X=-80, Y=215)
    final Path armPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(0, 75, -55, 110, -80, 215);

    // Draw Tonearm Shadow (only shadow translates with lift)
    final Paint armShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur);
    
    canvas.save();
    canvas.translate(shadowOffset * 0.7, shadowOffset);
    canvas.drawPath(armPath, armShadowPaint);
    // Draw counterweight shadow
    canvas.drawRect(Rect.fromCenter(center: const Offset(0, -25), width: 12, height: 18), Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur));
    canvas.restore();

    // Draw Silver Metallic Rigid Tonearm Tube (Strict constant length and geometry)
    final Paint tubePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
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
      ).createShader(const Rect.fromLTWH(-80, 0, 80, 215));
    canvas.drawPath(armPath, tubePaint);

    final Paint tubeHighlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.45);
    canvas.drawPath(armPath, tubeHighlightPaint);

    // 4. Counterweight (back stub, opposite side of rotation)
    final Paint weightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.grey.shade900,
          Colors.grey.shade700,
          Colors.grey.shade900,
        ],
      ).createShader(const Rect.fromLTWH(-6, -32, 12, 18));
    canvas.drawRect(Rect.fromCenter(center: const Offset(0, -22), width: 10, height: 14), weightPaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(0, -28), width: 14, height: 5), Paint()..color = Colors.black);

    // 5. Headshell / Cartridge & Stylus (at the end of tube: -80, 215)
    canvas.save();
    canvas.translate(-80, 215);
    canvas.rotate(-angle * 0.32); // Angled headshell offset

    // Cartridge plate
    final Paint headshellPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.grey.shade800,
          Colors.black,
        ],
      ).createShader(const Rect.fromLTWH(-7, 0, 14, 34));
    
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-7, 0, 14, 32), const Radius.circular(2.0)), headshellPaint);

    // Finger Lift (metallic pin on the right)
    final Paint fingerLiftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.grey.shade400;
    canvas.drawLine(const Offset(7, 8), const Offset(13, 10), fingerLiftPaint);
    canvas.drawLine(const Offset(13, 10), const Offset(14, 7), fingerLiftPaint);

    // Cartridge Brand Accent / Stylus (only the needle tip touches the record)
    canvas.drawRect(const Rect.fromLTWH(-5, 23, 10, 5), Paint()..color = primaryColor);

    // Stylus Needle point
    canvas.drawCircle(const Offset(0, 28), 1.0, Paint()..color = Colors.white.withValues(alpha: 0.8));

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
