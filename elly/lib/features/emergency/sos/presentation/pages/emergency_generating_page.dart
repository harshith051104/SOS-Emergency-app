/// emergency_generating_page.dart
///
/// Displays the "Generating Emergency Packet..." sequential verification checklist.
/// Items: Time, Location, Device Status, Medical Profile, Emergency Contacts, Completed.
/// Reads [generatingProgress] from the controller and shows animated checkmarks.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/enums/emergency_status.dart';
import '../providers/emergency_providers.dart';

class EmergencyGeneratingPage extends ConsumerWidget {
  const EmergencyGeneratingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = ref.watch(emergencyControllerProvider.select((s) => s.generatingProgress));

    // Listen for state change to navigate to live session dashboard
    ref.listen<EmergencyStatus>(
      emergencyStatusProvider,
      (previous, next) {
        if (!context.mounted) return;
        if (next == EmergencyStatus.active) {
          context.go(AppRoutes.emergencySession);
        } else if (next == EmergencyStatus.idle) {
          context.go(AppRoutes.home);
        }
      },
    );

    final items = [
      _ChecklistItem(label: 'Time', targetProgress: 1),
      _ChecklistItem(label: 'Location', targetProgress: 2),
      _ChecklistItem(label: 'Device Status', targetProgress: 3),
      _ChecklistItem(label: 'Medical Profile', targetProgress: 4),
      _ChecklistItem(label: 'Emergency Contacts', targetProgress: 5),
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
                // ── Animated Loader / Radar ──────────────────────────────
                Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress / 6.0,
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

                // ── Title ────────────────────────────────────────────────
                Text(
                  'Compiling Emergency Packet',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'ELLY is gathering critical telemetry data for responders...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // ── Checklist items ──────────────────────────────────────
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
                    children: items.map((item) {
                      final isCompleted = progress >= item.targetProgress;
                      final isCurrent = progress == item.targetProgress - 1;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? AppColors.successGreen
                                    : isCurrent
                                        ? AppColors.sosPrimary.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                border: Border.all(
                                  color: isCompleted
                                      ? AppColors.successGreen
                                      : isCurrent
                                          ? AppColors.sosPrimary
                                          : theme.colorScheme.outlineVariant,
                                  width: 2,
                                ),
                              ),
                              child: isCompleted
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
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
                            Text(
                              item.label,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: isCompleted || isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: isCompleted
                                    ? theme.colorScheme.onSurface
                                    : isCurrent
                                        ? AppColors.sosPrimary
                                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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

class _ChecklistItem {
  const _ChecklistItem({required this.label, required this.targetProgress});
  final String label;
  final int targetProgress;
}
