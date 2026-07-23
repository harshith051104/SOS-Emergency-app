/// emergency_report_page.dart
///
/// Summary screen displayed after the emergency session is ended.
/// Features:
///   - Large green check mark (Emergency Closed)
///   - Key session stats (duration, contacts notified, contacts responded, location shared)
///   - Reset to idle and return home button

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../providers/emergency_providers.dart';
import '../../domain/entities/emergency_session.dart';

class EmergencyReportPage extends ConsumerWidget {
  const EmergencyReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final controllerState = ref.watch(emergencyControllerProvider);
    final session = controllerState.activeSession;

    // Fallback if session is null
    final duration = session?.duration ?? Duration.zero;
    final totalNotified = session?.responderStatuses.length ?? 0;
    final totalAck = session?.responderStatuses
            .where((s) => s.state == ResponderSessionState.accepted)
            .length ??
        0;

    final durationString = _formatDuration(duration);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Closed Indicator ───────────────────────────────────
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: AppColors.successGreen,
                      size: 52,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Title ───────────────────────────────────────────────
                  Text(
                    'Emergency Closed',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All responders have been notified that you are safe.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 36),

                  // ── Session Report Summary Card ─────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'EMERGENCY SESSION REPORT',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.sosPrimary,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildReportRow(context, 'Trigger Type', 'Manual SOS'),
                        _buildReportRow(context, 'Session ID', session?.sessionId ?? '#EL-MOCK'),
                        _buildReportRow(context, 'Duration', durationString),
                        _buildReportRow(context, 'Contacts Notified', '$totalNotified'),
                        _buildReportRow(context, 'Responded', '$totalAck'),
                        _buildReportRow(context, 'Location Shared', '✓ Yes (Live)'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── Return Home Button ──────────────────────────────────
                  ElevatedButton.icon(
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Return Home'),
                    onPressed: () => _returnHome(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: AppColors.successOnGreen,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds < 60) {
      return '${d.inSeconds} seconds';
    }
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m min $s sec';
  }

  void _returnHome(BuildContext context, WidgetRef ref) {
    ref.read(emergencyControllerProvider.notifier).resetToIdle();
    context.go('/');
  }
}
