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
  bool _isDragging = false;
  String? _lastSongId;
  bool _isNewSongStarting = false;

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

    // Clamp to valid physical travel limits (2 to 40 degrees)
    draggedAngle = draggedAngle.clamp(2.0 * (pi / 180.0), 40.0 * (pi / 180.0));

    setState(() {
      _isDragging = true;
    });

    const double startAngle = 27.5 * (pi / 180.0);
    const double parkedAngle = 2.0 * (pi / 180.0);
    final controller = ref.read(playbackControllerProvider);
    final playbackState = ref.read(playbackStateProvider);

    if (draggedAngle >= startAngle) {
      // ZONE B: Stylus is above playable grooves -> Resume Playback
      setState(() {
        _dragAngle = draggedAngle;
      });
      if (playbackState.status == PlaybackStatus.paused) {
        controller.play();
      }
    } else {
      // ZONE A: Stylus is dragged away from grooves -> Pause and snap to PARKED position
      setState(() {
        _dragAngle = parkedAngle;
      });
      if (playbackState.status == PlaybackStatus.playing) {
        controller.pause();
      }
    }
  }

  void _endDrag() {
    if (!_isDragging) return;

    const double startAngle = 27.5 * (pi / 180.0);
    final double finalAngle = _dragAngle ?? (2.0 * (pi / 180.0));

    setState(() {
      _isDragging = false;
      _dragAngle = null;
    });

    final controller = ref.read(playbackControllerProvider);

    if (finalAngle >= startAngle) {
      controller.play();
    } else {
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
    final String? songId = currentSong?.id;

    // Detect track change and flag it to reset positions instantly
    if (songId != _lastSongId) {
      _lastSongId = songId;
      _isNewSongStarting = true;
    }

    // Unflag once the media player position has reset to the beginning of the new track
    if (_isNewSongStarting && position.inMilliseconds < 500) {
      _isNewSongStarting = false;
    }

    // Force progress to 0% during track load/transition to avoid stale positions
    final double progress = (_isNewSongStarting || duration.inMilliseconds == 0)
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    final isPlaying = currentSong != null && playbackState.status == PlaybackStatus.playing;

    double targetAngle;
    double targetLift;

    if (_isDragging && _dragAngle != null) {
      // User is actively dragging: follows finger and lifts off vinyl
      targetAngle = _dragAngle!;
      targetLift = 1.0; // Lifted off the record
    } else if (isPlaying) {
      // Playing: moves slowly across grooves strictly based on playback progress
      // Calibrated Start Angle: 27.5 degrees (outermost groove, radius 140px)
      // Calibrated End Angle: 40.0 degrees (innermost groove, radius 92.4px)
      targetAngle = (27.5 + progress * 12.5) * (pi / 180.0);
      targetLift = 0.0; // Lands gently on the record
    } else {
      // Stopped / Paused: always returns COMPLETELY to the predefined parked position beside the vinyl
      targetAngle = 2.0 * (pi / 180.0);
      targetLift = 1.0; // Fully raised/parked
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) => _handleDrag(details.localPosition),
      onPanUpdate: (details) => _handleDrag(details.localPosition),
      onPanEnd: (_) => _endDrag(),
      onPanCancel: () => _endDrag(),
      child: Stack(
        key: ValueKey(songId), // Reset stack state and key animations on track change
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: isPlaying ? 27.5 * (pi / 180.0) : 2.0 * (pi / 180.0), end: targetAngle),
            duration: Duration(milliseconds: _isDragging ? 40 : 200),
            curve: _isDragging ? Curves.linear : Curves.easeOut,
            builder: (context, angle, child) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1.0, end: targetLift),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
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
