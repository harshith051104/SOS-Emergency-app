/// emergency_success_widget.dart
///
/// Animated success state widget showing a green check mark drawn
/// with a path animation (no external packages required).

library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Displays an animated check mark circle for the activated state.
class EmergencySuccessWidget extends StatefulWidget {
  const EmergencySuccessWidget({super.key});

  @override
  State<EmergencySuccessWidget> createState() =>
      _EmergencySuccessWidgetState();
}

class _EmergencySuccessWidgetState extends State<EmergencySuccessWidget>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _checkController;
  late AnimationController _pulseController;

  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _circleAnimation = CurvedAnimation(
      parent: _circleController,
      curve: Curves.easeOut,
    );

    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Sequence: circle first, then check.
    _circleController.forward().then((_) {
      if (mounted) _checkController.forward();
    });
  }

  @override
  void dispose() {
    _circleController.dispose();
    _checkController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _circleAnimation,
        _checkAnimation,
        _pulseAnimation,
      ]),
      builder: (context, _) {
        return ScaleTransition(
          scale: _pulseAnimation,
          child: SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _SuccessPainter(
                circleProgress: _circleAnimation.value,
                checkProgress: _checkAnimation.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Custom Painter ────────────────────────────────────────────────────────────

class _SuccessPainter extends CustomPainter {
  _SuccessPainter({
    required this.circleProgress,
    required this.checkProgress,
  });

  final double circleProgress;
  final double checkProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // ── Background fill ────────────────────────────────────────────────────
    final bgPaint = Paint()
      ..color = AppColors.successGreen.withValues(alpha: 0.12 * circleProgress)

      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * circleProgress, bgPaint);

    // ── Circle stroke ──────────────────────────────────────────────────────
    final circlePaint = Paint()
      ..color = AppColors.successGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90 degrees (top)
      2 * 3.14159 * circleProgress,
      false,
      circlePaint,
    );

    // ── Check mark ─────────────────────────────────────────────────────────
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = AppColors.successGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Check mark path: defined as two segments.
      // Start → midpoint → endpoint.
      final startPoint = Offset(size.width * 0.28, size.height * 0.52);
      final midPoint = Offset(size.width * 0.44, size.height * 0.65);
      final endPoint = Offset(size.width * 0.72, size.height * 0.38);

      // First segment progress.
      const seg1Weight = 0.45;
      const seg2Start = seg1Weight;

      final path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);

      if (checkProgress <= seg1Weight) {
        final t = checkProgress / seg1Weight;
        final x = startPoint.dx + (midPoint.dx - startPoint.dx) * t;
        final y = startPoint.dy + (midPoint.dy - startPoint.dy) * t;
        path.lineTo(x, y);
      } else {
        path.lineTo(midPoint.dx, midPoint.dy);
        final t = (checkProgress - seg2Start) / (1 - seg2Start);
        final x = midPoint.dx + (endPoint.dx - midPoint.dx) * t;
        final y = midPoint.dy + (endPoint.dy - midPoint.dy) * t;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_SuccessPainter oldDelegate) {
    return oldDelegate.circleProgress != circleProgress ||
        oldDelegate.checkProgress != checkProgress;
  }
}
