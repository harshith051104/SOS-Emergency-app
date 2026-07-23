/// emergency_countdown_widget.dart
///
/// Animated countdown number that scales in/out on each tick.
/// Designed to be reusable across any trigger type (manual, voice, etc.)

library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Displays an animated countdown number with a scale animation on each tick.
///
/// [value] is the current countdown integer (e.g., 5, 4, 3, 2, 1).
class EmergencyCountdownWidget extends StatefulWidget {
  const EmergencyCountdownWidget({
    super.key,
    required this.value,
  });

  final int value;

  @override
  State<EmergencyCountdownWidget> createState() =>
      _EmergencyCountdownWidgetState();
}

class _EmergencyCountdownWidgetState extends State<EmergencyCountdownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _controller.forward();
  }

  @override
  void didUpdateWidget(EmergencyCountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.forward(from: 0);
    }
  }

  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.95)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_controller);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Text(
              '${widget.value}',
              style: theme.textTheme.displayLarge?.copyWith(
                color: AppColors.sosPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 100,
              ),
            ),
          ),
        );
      },
    );
  }
}
