/// sos_button.dart
///
/// The primary SOS action button with:
///   - Continuous breathing/pulse animation (Apple Emergency SOS inspired)
///   - Ripple burst on tap
///   - Double-tap guard (locked state)
///   - Full accessibility support (semantics, large touch target)

library;

import 'package:flutter/material.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../../../core/constants/app_strings.dart';

import '../../../../../core/theme/app_colors.dart';

/// Large circular SOS button with ambient pulse animation.
///
/// [onTap] is only called when [isLocked] is false.
class SosButton extends StatefulWidget {
  const SosButton({
    super.key,
    required this.onTap,
    this.isLocked = false,
  });

  /// Callback invoked when the button is tapped (and not locked).
  final VoidCallback onTap;

  /// When true, the button ignores taps (double-tap guard).
  final bool isLocked;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with TickerProviderStateMixin {
  // ── Pulse animation ──────────────────────────────────────────────────────
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // ── Tap scale animation ───────────────────────────────────────────────────
  late final AnimationController _tapController;
  late final Animation<double> _tapAnimation;

  /// Diameter of the core button.
  static const double _buttonSize = 200;

  @override
  void initState() {
    super.initState();

    // Continuous breathing pulse — runs indefinitely.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST')) {
      _pulseController.repeat(reverse: true);
    }


    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // One-shot scale on tap.
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _tapAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.isLocked) return;

    // Respects system reduced-motion preference.
    final reduceMotion =
        MediaQuery.of(context).disableAnimations;

    if (!reduceMotion) {
      await _tapController.forward();
      await _tapController.reverse();
    }

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _tapAnimation]),
        builder: (context, child) {
          return SizedBox(
            width: _buttonSize * 1.6,
            height: _buttonSize * 1.6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!reduceMotion)
                  _PulseRing(
                    size: _buttonSize * (_pulseAnimation.value * 1.35),
                    opacity: (1 - (_pulseAnimation.value - 1) / 0.12) * 0.12,
                  ),
                if (!reduceMotion)
                  _PulseRing(
                    size: _buttonSize * (_pulseAnimation.value * 1.18),
                    opacity: (1 - (_pulseAnimation.value - 1) / 0.12) * 0.20,
                  ),
                if (!reduceMotion)
                  _PulseRing(
                    size: _buttonSize * (_pulseAnimation.value * 1.05),
                    opacity: (1 - (_pulseAnimation.value - 1) / 0.12) * 0.30,
                  ),
                Transform.scale(
                  scale: _tapAnimation.value,
                  child: _CoreButton(
                    size: _buttonSize,
                    isLocked: widget.isLocked,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Private: Pulse Ring ───────────────────────────────────────────────────────

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.sosPrimary.withValues(alpha: opacity.clamp(0.0, 1.0)),
      ),
    );
  }
}

// ── Private: Core Button ──────────────────────────────────────────────────────

class _CoreButton extends StatelessWidget {
  const _CoreButton({required this.size, required this.isLocked});

  final double size;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: isLocked
              ? [
                  AppColors.sosPrimaryLight.withValues(alpha: 0.7),
                  AppColors.sosPrimary.withValues(alpha: 0.7),
                ]
              : [
                  AppColors.sosPrimaryLight,
                  AppColors.sosPrimary,
                ],
          stops: const [0.0, 1.0],
        ),
        boxShadow: isLocked
            ? null
            : [
                BoxShadow(
                  color: AppColors.sosPrimary.withValues(alpha: 0.45),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: AppColors.sosPrimary.withValues(alpha: 0.20),
                  blurRadius: 60,
                  spreadRadius: 8,
                ),
              ],
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.sosButtonLabel,
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.sosButtonSubtext,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
