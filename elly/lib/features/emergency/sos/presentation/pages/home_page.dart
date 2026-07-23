/// home_page.dart
///
/// The primary home screen of the ELLY app.
/// Displays the pulsing SOS button at centre stage.
///
/// Flow:
///   Tap SOS → requestConfirmation() → state: awaitingConfirmation
///   ref.listen detects awaitingConfirmation → pushes /emergency/confirmation
///
/// Settings icon (top right) → navigates to /responders

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/enums/emergency_status.dart';
import '../providers/emergency_providers.dart';
import '../widgets/sos_button.dart';

/// Home page — entry point of the emergency flow.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = ref.watch(emergencyControllerProvider.notifier).isLocked;

    // Listen for state transitions to handle navigation.
    ref.listen<EmergencyStatus>(emergencyStatusProvider, (previous, next) {
      if (!context.mounted) return;
      switch (next) {
        case EmergencyStatus.awaitingConfirmation:
          context.go(AppRoutes.emergencyConfirmation);
        case EmergencyStatus.generatingPacket:
          context.go(AppRoutes.emergencyGenerating);
        case EmergencyStatus.active:
          context.go(AppRoutes.emergencySession);
        case EmergencyStatus.sessionCompleted:
          context.go(AppRoutes.emergencyComplete);
        case EmergencyStatus.idle:
          context.go(AppRoutes.home);
        default:
          break;
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ── Background gradient ─────────────────────────────────────
            _BackgroundGradient(),

            // ── Main content ────────────────────────────────────────────
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  // ── App branding ──────────────────────────────────────
                  _AppBranding(),

                  const SizedBox(height: 64),

                  // ── SOS Button ────────────────────────────────────────
                  SosButton(
                    isLocked: isLocked,
                    onTap: () => _onSosTap(ref),
                  ),

                  const SizedBox(height: 48),

                  // ── Hint text ─────────────────────────────────────────
                  AnimatedOpacity(
                    opacity: isLocked ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: const _HintText(),
                  ),
                ],
              ),
            ),
          ),

            // ── Settings icon (top right) → Responders page ────────────
            Positioned(
              top: 16,
              right: 16,
              child: Tooltip(
                message: 'Manage Emergency Responders',
                child: IconButton(
                  icon: const Icon(Icons.manage_accounts_outlined),
                  onPressed: () => context.push(AppRoutes.responders),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSosTap(WidgetRef ref) async {
    await ref.read(emergencyControllerProvider.notifier).requestConfirmation();
  }
}

// ── Private Widgets ───────────────────────────────────────────────────────────

class _BackgroundGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: isDark
              ? [
                  AppColors.sosPrimary.withOpacity(0.06),
                  AppColors.surfaceDark,
                ]
              : [
                  AppColors.sosPrimaryFaint,
                  AppColors.surfaceLight,
                ],
        ),
      ),
    );
  }
}

class _AppBranding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.sosPrimary.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.sosPrimary,
                child: const Center(
                  child: Icon(
                    Icons.security,
                    color: AppColors.sosOnPrimary,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.appName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.appTagline,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _HintText extends StatelessWidget {
  const _HintText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Tap to send emergency alert',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
    );
  }
}
