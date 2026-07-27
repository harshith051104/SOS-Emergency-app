/// emergency_countdown_page.dart
///
/// Dedicated SOS Countdown Screen focused exclusively on the 10-second timer
/// and cancellation protection. Navigates on completion event.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/router/app_router.dart';
import '../../domain/entities/sos_countdown_state.dart';
import '../providers/emergency_providers.dart';
import '../providers/sos_countdown_provider.dart';
import '../controllers/emergency_session_controller.dart';
import '../widgets/emergency_countdown_widget.dart';


class EmergencyCountdownPage extends ConsumerStatefulWidget {
  const EmergencyCountdownPage({super.key});

  @override
  ConsumerState<EmergencyCountdownPage> createState() => _EmergencyCountdownPageState();
}

class _EmergencyCountdownPageState extends ConsumerState<EmergencyCountdownPage> {
  @override
  void initState() {
    super.initState();
    // Auto-start 10s countdown if engine is idle
    Future.microtask(() {
      if (!mounted) return;
      final engineState = ref.read(sosCountdownStateProvider);
      if (engineState.status == SosCountdownStatus.idle) {
        ref.read(sosCountdownStateProvider.notifier).startCountdown();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final countdownModel = ref.watch(sosCountdownStateProvider);

    ref.listen<SosCountdownStateModel>(sosCountdownStateProvider, (previous, next) {
      if (!mounted) return;
      if (next.status == SosCountdownStatus.cancelled) {
        context.go(AppRoutes.home);
      } else if (next.status == SosCountdownStatus.completed) {
        ref.read(emergencySessionControllerProvider.notifier).onCountdownCompleted();
        context.go(AppRoutes.emergencyServiceSelection);
      }
    });


    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleCancel(context);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              _CountdownBackground(progress: countdownModel.secondsRemaining),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Trigger Source Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.sosPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.sosPrimary.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.sosPrimary),
                            const SizedBox(width: 8),
                            Text(
                              'TRIGGER: ${countdownModel.triggerSource}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.sosPrimary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Large Countdown Number
                      EmergencyCountdownWidget(
                        key: ValueKey(countdownModel.secondsRemaining),
                        value: countdownModel.secondsRemaining,
                      ),

                      const SizedBox(height: 24),

                      // Warning Title & Explanation
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          AppStrings.countdownTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Emergency services & SOS Circle contacts will be notified automatically when countdown finishes.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 48),

                      // Cancel Button
                      ElevatedButton.icon(
                        onPressed: () => _handleCancel(context),
                        icon: const Icon(Icons.shield_rounded, size: 22),
                        label: const Text('I\'M SAFE — CANCEL EMERGENCY'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(280, 56),
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppColors.sosPrimary,
                          elevation: 0,
                          side: const BorderSide(color: AppColors.sosPrimary, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCancel(BuildContext context) {
    ref.read(sosCountdownStateProvider.notifier).cancelCountdown();
    ref.read(emergencyControllerProvider.notifier).cancelCountdown();
    context.go(AppRoutes.home);
  }
}

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
          radius: 0.9,
          colors: isDark
              ? [AppColors.sosPrimary.withValues(alpha: 0.14), AppColors.surfaceDark]
              : [AppColors.sosPrimary.withValues(alpha: 0.09), AppColors.surfaceLight],
        ),
      ),
    );
  }
}
