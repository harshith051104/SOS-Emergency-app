/// emergency_countdown_page.dart
///
/// Full-screen countdown page displayed after the user confirms activation.
/// Features:
///   - Large animated countdown number
///   - Cancel button to abort
///   - PopScope prevents accidental back-navigation
///   - Listens for state transitions to navigate to activated screen
///   - Reusable: works for any [EmergencyType] trigger

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/router/app_router.dart';
import '../../domain/enums/emergency_status.dart';
import '../providers/emergency_providers.dart';
import '../widgets/emergency_countdown_widget.dart';

/// Full-screen countdown before emergency activation.
class EmergencyCountdownPage extends ConsumerWidget {
  const EmergencyCountdownPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdownValue = ref.watch(countdownValueProvider);
    final status = ref.watch(emergencyStatusProvider);

    // Listen for state change to navigate to active session or complete screen.
    ref.listen<EmergencyStatus>(emergencyStatusProvider, (previous, next) {
      if (!context.mounted) return;

      switch (next) {
        case EmergencyStatus.generatingPacket:
          context.go(AppRoutes.emergencyGenerating);
        case EmergencyStatus.active:
          context.go(AppRoutes.emergencySession);
        case EmergencyStatus.sessionCompleted:
          context.go(AppRoutes.emergencyComplete);
        case EmergencyStatus.idle:
        case EmergencyStatus.cancelled:
          context.go('/');
        case EmergencyStatus.failed:
          context.go('/');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency activation failed. Please try again.'),
              backgroundColor: AppColors.sosPrimary,
            ),
          );
        default:
          break;
      }
    });

    return PopScope(
      // Prevent hardware back from exiting the countdown without cancelling.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleCancel(context, ref);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // ── Animated background ──────────────────────────────────
              _CountdownBackground(progress: countdownValue),

              // ── Main content ─────────────────────────────────────────
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Countdown number ────────────────────────────────
                    EmergencyCountdownWidget(key: ValueKey(countdownValue), value: countdownValue),

                    const SizedBox(height: 32),

                    // ── Title ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        AppStrings.countdownTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Status indicator ────────────────────────────────
                    if (status == EmergencyStatus.activating)
                      const _ActivatingIndicator(),
                  ],
                ),
              ),

              // ── Cancel button ─────────────────────────────────────────
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: Center(
                  child: OutlinedButton(
                    onPressed: status == EmergencyStatus.activating
                        ? null
                        : () => _handleCancel(context, ref),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(160, 52),
                      foregroundColor: AppColors.sosPrimary,
                      side: const BorderSide(
                        color: AppColors.sosPrimary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('I\'M SAFE — CANCEL'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref) async {
    await ref.read(emergencyControllerProvider.notifier).cancelCountdown();
  }
}

// ── Private Widgets ───────────────────────────────────────────────────────────

/// Subtle animated background that pulses red during countdown.
class _CountdownBackground extends StatelessWidget {
  const _CountdownBackground({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: isDark
              ? [
                  AppColors.sosPrimary.withOpacity(0.10),
                  AppColors.surfaceDark,
                ]
              : [
                  AppColors.sosPrimary.withOpacity(0.07),
                  AppColors.surfaceLight,
                ],
        ),
      ),
    );
  }
}

/// Shown while the activation call is in progress (status = activating).
class _ActivatingIndicator extends StatelessWidget {
  const _ActivatingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.sosPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Activating…',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.sosPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
