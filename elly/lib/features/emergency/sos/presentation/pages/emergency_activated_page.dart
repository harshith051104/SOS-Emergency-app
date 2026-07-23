/// emergency_activated_page.dart
///
/// Success screen displayed after emergency is activated.
/// Features:
///   - Custom animated check mark (no external animation packages)
///   - PopScope prevents back-navigation to countdown
///   - "View Response Status" button navigates to live engine timeline
///   - Return Home button resets state machine

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../providers/emergency_providers.dart';
import '../widgets/emergency_success_widget.dart';

/// Full-screen activated / success page.
class EmergencyActivatedPage extends ConsumerWidget {
  const EmergencyActivatedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(activeEmergencyEventProvider);
    final theme = Theme.of(context);

    return PopScope(
      // Block back navigation from the activated screen.
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Success animation ───────────────────────────────────
                  const EmergencySuccessWidget(),

                  const SizedBox(height: 40),

                  // ── Title ───────────────────────────────────────────────
                  Text(
                    AppStrings.activatedTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Description ─────────────────────────────────────────
                  Text(
                    AppStrings.activatedDescription,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),

                  // ── Event ID (debug/audit) ──────────────────────────────
                  if (event != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'ID: ${event.id.substring(0, 8)}…',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.5),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // ── View Response Status button ──────────────────────────
                  ElevatedButton.icon(
                    icon: const Icon(Icons.monitor_heart_outlined),
                    label: const Text('View Response Status'),
                    onPressed: () =>
                        context.push(AppRoutes.emergencyResponseStatus),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sosPrimary,
                      foregroundColor: AppColors.sosOnPrimary,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Return Home button ───────────────────────────────────
                  OutlinedButton.icon(
                    icon: const Icon(Icons.home_outlined),
                    label: Text(AppStrings.activatedReturnHome),
                    onPressed: () => _returnHome(context, ref),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _returnHome(BuildContext context, WidgetRef ref) {
    ref.read(emergencyControllerProvider.notifier).resetToIdle();
    context.go('/');
  }
}
