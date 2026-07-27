/// emergency_generating_page.dart
///
/// Preparing Emergency Dispatch screen (Sprint 4.1).
/// Sequentially animates 4 dispatch compilation steps, resolves the selected service's
/// emergency helpline number, launches the phone dialer, and transitions to live EmergencySession.

library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/emergency_number_resolver.dart';
import '../providers/emergency_providers.dart';
import '../providers/emergency_service_provider.dart';
import '../controllers/emergency_session_controller.dart';

class EmergencyGeneratingPage extends ConsumerStatefulWidget {
  const EmergencyGeneratingPage({super.key});

  @override
  ConsumerState<EmergencyGeneratingPage> createState() => _EmergencyGeneratingPageState();
}

class _EmergencyGeneratingPageState extends ConsumerState<EmergencyGeneratingPage> {
  int _currentStep = 1;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _startSequentialDispatchAnimation();
  }

  void _startSequentialDispatchAnimation() {
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentStep < 4) {
        setState(() => _currentStep++);
      } else {
        timer.cancel();
        _finalizeDispatchAndCall();
      }
    });
  }

  Future<void> _finalizeDispatchAndCall() async {
    final selectionState = ref.read(emergencyServiceProvider);
    final selectedService = selectionState.selectedService;
    final number = selectedService?.emergencyNumber ?? '112';

    // Transition state
    ref.read(emergencySessionControllerProvider.notifier).startCommunicationStarted();
    ref.read(emergencySessionControllerProvider.notifier).startEmergencySession();
    ref.read(emergencyControllerProvider.notifier).startGeneratingPacket(category: selectedService?.name);


    // Make dynamic phone call to selected helpline
    await EmergencyNumberResolver.makeEmergencyCall(number);

    if (mounted) {
      context.go(AppRoutes.home);
    }

  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedService = ref.watch(emergencyServiceProvider).selectedService;

    final steps = [
      const _DispatchStep(label: 'Initializing Monitoring Engine', stepIndex: 1),
      const _DispatchStep(label: 'Compiling Telemetry Packet', stepIndex: 2),
      const _DispatchStep(label: 'Selecting Optimal Transport', stepIndex: 3),
      _DispatchStep(
        label: 'Dispatching Emergency Alerts (${selectedService?.name ?? '112'})',
        stepIndex: 4,
      ),
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Animated Loader / Radar
                Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _currentStep / 4.0,
                          strokeWidth: 6,
                          backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                          color: AppColors.sosPrimary,
                        ),
                        const Icon(
                          Icons.security_rounded,
                          size: 36,
                          color: AppColors.sosPrimary,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Title
                Text(
                  'Preparing Emergency Dispatch',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Connecting to ${selectedService?.name ?? 'Universal Helpline'} (${selectedService?.emergencyNumber ?? '112'})...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.sosPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Checklist Items
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    children: steps.map((step) {
                      final isDone = _currentStep > step.stepIndex;
                      final isCurrent = _currentStep == step.stepIndex;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone
                                    ? AppColors.successGreen
                                    : isCurrent
                                        ? AppColors.sosPrimary.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                border: Border.all(
                                  color: isDone
                                      ? AppColors.successGreen
                                      : isCurrent
                                          ? AppColors.sosPrimary
                                          : theme.colorScheme.outlineVariant,
                                  width: 2,
                                ),
                              ),
                              child: isDone
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : isCurrent
                                      ? const Center(
                                          child: SizedBox(
                                            width: 8,
                                            height: 8,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: AppColors.sosPrimary,
                                            ),
                                          ),
                                        )
                                      : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                step.label,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: isDone || isCurrent ? FontWeight.w700 : FontWeight.normal,
                                  color: isDone
                                      ? theme.colorScheme.onSurface
                                      : isCurrent
                                          ? AppColors.sosPrimary
                                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DispatchStep {
  const _DispatchStep({required this.label, required this.stepIndex});
  final String label;
  final int stepIndex;
}
