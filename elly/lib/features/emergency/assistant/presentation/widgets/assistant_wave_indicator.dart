/// assistant_wave_indicator.dart
///
/// Pulse wave animation widget that dynamically visually reflects ELLY's active states.
///
/// ANIMATION STRATEGY: The AnimationController is passed directly as the `repaint`
/// Listenable to _WavePainter (via CustomPainter's repaint parameter). This means
/// each tick calls markNeedsPaint() directly — ZERO widget rebuilds per frame.
/// AnimatedBuilder (setState every 16ms) was deliberately avoided to prevent
/// semantics.parentDataDirty assertions and layout cascade errors.

library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:elly/core/theme/app_colors.dart';
import '../../domain/entities/assistant_state.dart';

class AssistantWaveIndicator extends StatefulWidget {
  const AssistantWaveIndicator({
    required this.state,
    super.key,
  });

  final AssistantState state;

  @override
  State<AssistantWaveIndicator> createState() => _AssistantWaveIndicatorState();
}

class _AssistantWaveIndicatorState extends State<AssistantWaveIndicator>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late _WavePainter _painter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Create the painter once — it registers _controller as its repaint Listenable.
    // Every tick → controller.notifyListeners() → markNeedsPaint() on the render object.
    // No setState, no widget rebuild, no semantics dirtying.
    _painter = _WavePainter(animation: _controller, state: widget.state);
  }

  @override
  void didUpdateWidget(AssistantWaveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only recreate the painter when the AssistantState changes.
    // The controller reference stays stable, so no listener churn.
    if (oldWidget.state != widget.state) {
      _painter = _WavePainter(animation: _controller, state: widget.state);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive ||
        lifecycleState == AppLifecycleState.detached) {
      if (_controller.isAnimating) _controller.stop();
    } else if (lifecycleState == AppLifecycleState.resumed) {
      if (!_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ExcludeSemantics: the wave is purely decorative — no a11y meaning.
    //
    // NO inner RepaintBoundary here. The ListView that contains _EllyAssistantPanel
    // already adds a RepaintBoundary per child via SliverChildListDelegate. Adding
    // a second (nested) boundary created a nested OffsetLayer which caused
    // markNeedsCompositingBitsUpdate() to cascade through the parent render tree
    // on every animation tick → triggered layout invalidation before flushSemantics()
    // → "!semantics.parentDataDirty" assertion every frame.
    return RepaintBoundary(
      child: CustomPaint(
        size: const Size(80, 80),
        painter: _painter,
        isComplex: true,
        willChange: true,
      ),
    );

  }
}

// ── Painter ──────────────────────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.animation,
    required this.state,
  }) : super(repaint: animation); // ← Listenable drives markNeedsPaint directly

  final Animation<double> animation;
  final AssistantState state;

  // Read progress from the animation inside paint() — always current value.
  double get _progress => animation.value;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = _progress;
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    Color coreColor;
    Color glowColor;
    int waveCount;

    // Adjust colors and concentric wave frequencies depending on State
    switch (state) {
      case AssistantState.listening:
        coreColor = const Color(0xFF00E676); // Green
        glowColor = const Color(0xFF00E676).withValues(alpha: 0.15);
        waveCount = 3;
        break;
      case AssistantState.thinking:
        coreColor = const Color(0xFF7C4DFF); // Purple
        glowColor = const Color(0xFF7C4DFF).withValues(alpha: 0.12);
        waveCount = 4;
        break;
      case AssistantState.speaking:
        coreColor = AppColors.sosPrimary;
        glowColor = AppColors.sosPrimary.withValues(alpha: 0.18);
        waveCount = 3;
        break;
      case AssistantState.transcribing:
        coreColor = Colors.cyan;
        glowColor = Colors.cyan.withValues(alpha: 0.15);
        waveCount = 2;
        break;
      case AssistantState.muted:
        coreColor = Colors.grey;
        glowColor = Colors.grey.withValues(alpha: 0.08);
        waveCount = 1;
        break;
      default:
        coreColor = AppColors.sosPrimary.withValues(alpha: 0.7);
        glowColor = AppColors.sosPrimary.withValues(alpha: 0.08);
        waveCount = 2;
    }

    // Draw concentric pulse waves
    for (int i = waveCount; i > 0; i--) {
      final waveProgress = (progress + (i / waveCount)) % 1.0;
      final radius = maxRadius * waveProgress;
      final opacity = (1.0 - waveProgress) * 0.7;

      paint.color = glowColor.withValues(alpha: glowColor.a * opacity);
      canvas.drawCircle(center, radius, paint);
    }

    // Draw central glowing dot with micro-breathing
    paint.color = coreColor;
    final breathingFactor = 1.0 + (0.08 * math.sin(progress * 2 * math.pi));
    canvas.drawCircle(center, (maxRadius * 0.45) * breathingFactor, paint);

    // Inner icon representation
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    if (state == AssistantState.listening) {
      canvas.drawLine(Offset(center.dx, center.dy - 6), Offset(center.dx, center.dy + 6), iconPaint);
    } else if (state == AssistantState.speaking) {
      canvas.drawLine(Offset(center.dx - 5, center.dy - 4), Offset(center.dx - 5, center.dy + 4), iconPaint);
      canvas.drawLine(Offset(center.dx, center.dy - 8), Offset(center.dx, center.dy + 8), iconPaint);
      canvas.drawLine(Offset(center.dx + 5, center.dy - 4), Offset(center.dx + 5, center.dy + 4), iconPaint);
    } else if (state == AssistantState.thinking) {
      final rect = Rect.fromCircle(center: center, radius: 6);
      canvas.drawArc(rect, progress * 2 * math.pi, math.pi * 0.7, false, iconPaint);
    } else {
      canvas.drawCircle(center, 3, iconPaint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    // Only repaint when state changes — the Listenable (animation) handles
    // the frame-by-frame repaints automatically without calling shouldRepaint.
    return oldDelegate.state != state;
  }
}
