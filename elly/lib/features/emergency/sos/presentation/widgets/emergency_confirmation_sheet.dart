/// emergency_confirmation_sheet.dart
///
/// Modal bottom sheet that asks the user to confirm emergency activation.
/// Uses Material 3 bottom sheet styling with drag handle.

library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';

/// Shows the emergency confirmation bottom sheet.
///
/// Call this via [showModalBottomSheet] to present it as a modal.
class EmergencyConfirmationSheet extends StatelessWidget {
  const EmergencyConfirmationSheet({
    super.key,
    required this.onCancel,
    required this.onActivate,
  });

  /// Called when the user taps Cancel.
  final VoidCallback onCancel;

  /// Called when the user taps Activate SOS.
  final VoidCallback onActivate;

  /// Convenience static method to show this sheet.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onCancel,
    required VoidCallback onActivate,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EmergencyConfirmationSheet(
        onCancel: onCancel,
        onActivate: onActivate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Warning Icon ──────────────────────────────────────────────
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.sosPrimary.withValues(alpha: 0.12),

                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.sosPrimary,
                size: 32,
              ),
            ),

            const SizedBox(height: 20),

            // ── Title ─────────────────────────────────────────────────────
            Text(
              AppStrings.confirmationTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // ── Description ───────────────────────────────────────────────
            Text(
              AppStrings.confirmationDescription,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // ── Activate Button ───────────────────────────────────────────
            Semantics(
              label: AppStrings.confirmationActivateSemanticLabel,
              button: true,
              child: ElevatedButton(
                onPressed: onActivate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sosPrimary,
                  foregroundColor: AppColors.sosOnPrimary,
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(
                  AppStrings.confirmationActivate,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.sosOnPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Cancel Button ─────────────────────────────────────────────
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text(AppStrings.confirmationCancel),
            ),
          ],
        ),
      ),
    );
  }
}
