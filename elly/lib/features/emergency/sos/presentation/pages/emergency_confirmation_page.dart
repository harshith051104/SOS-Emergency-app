/// emergency_confirmation_page.dart
///
/// 10-second Emergency Situation Selector & Auto-Activation Page.
/// Allows the user to select their emergency situation (Medical, Personal Safety,
/// Accident, Fire & Disaster, Mental Health, Child & Elderly) or auto-activates SOS.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/router/app_router.dart';
import '../../domain/enums/emergency_status.dart';
import '../providers/emergency_providers.dart';

/// Representation of an emergency category option.
class _EmergencyCategoryItem {
  const _EmergencyCategoryItem({
    required this.title,
    required this.description,
    required this.gradientColors,
    required this.icon,
  });

  final String title;
  final String description;
  final List<Color> gradientColors;
  final IconData icon;
}

const _emergencyCategories = [
  _EmergencyCategoryItem(
    title: 'Medical',
    description: 'Health emergency, illness, injury, or sudden condition',
    gradientColors: [Color(0xFFEF5350), Color(0xFFC62828)],
    icon: Icons.monitor_heart_rounded,
  ),
  _EmergencyCategoryItem(
    title: 'Personal Safety',
    description: 'Threat, harassment, violence, stalking, or feeling unsafe',
    gradientColors: [Color(0xFFAB47BC), Color(0xFF4A148C)],
    icon: Icons.security_rounded,
  ),
  _EmergencyCategoryItem(
    title: 'Accident',
    description: 'Vehicle accident, fall, or any kind of accident',
    gradientColors: [Color(0xFF42A5F5), Color(0xFF0D47A1)],
    icon: Icons.directions_car_rounded,
  ),
  _EmergencyCategoryItem(
    title: 'Fire & Disaster',
    description: 'Fire, gas leak, flood, earthquake, or other disaster',
    gradientColors: [Color(0xFFFFA726), Color(0xFFE65100)],
    icon: Icons.local_fire_department_rounded,
  ),
  _EmergencyCategoryItem(
    title: 'Mental Health',
    description: 'Panic attack, emotional crisis, stress, or suicidal thoughts',
    gradientColors: [Color(0xFF26A69A), Color(0xFF004D40)],
    icon: Icons.psychology_rounded,
  ),
  _EmergencyCategoryItem(
    title: 'Child & Elderly',
    description: 'Missing child, elderly emergency, or caregiver help',
    gradientColors: [Color(0xFF66BB6A), Color(0xFF1B5E20)],
    icon: Icons.family_restroom_rounded,
  ),
];

/// Full-screen 10-second confirmation page with 6 situation buttons.
class EmergencyConfirmationPage extends ConsumerStatefulWidget {
  const EmergencyConfirmationPage({super.key});

  @override
  ConsumerState<EmergencyConfirmationPage> createState() =>
      _EmergencyConfirmationPageState();
}

class _EmergencyConfirmationPageState
    extends ConsumerState<EmergencyConfirmationPage> {
  bool _showingSuccess = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final countdownValue = ref.watch(countdownValueProvider);
    final config = ref.watch(emergencyConfigProvider);
    final status = ref.watch(emergencyStatusProvider);

    // Navigation listener
    ref.listen<EmergencyStatus>(emergencyStatusProvider, (previous, next) {
      if (!context.mounted) return;

      switch (next) {
        case EmergencyStatus.active:
        case EmergencyStatus.activating:
        case EmergencyStatus.generatingPacket:
          context.go(AppRoutes.home);

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

    if (_showingSuccess) {
      return const _SafeSuccessPage();
    }

    final isActivating = status == EmergencyStatus.activating;
    final totalDuration = config.confirmationDuration > 0 ? config.confirmationDuration : 10;
    final progressFraction = (countdownValue / totalDuration).clamp(0.0, 1.0);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B101D) : const Color(0xFF0F172A),
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Header Bar ──────────────────────────────────────────
              _buildTopHeader(context, countdownValue, progressFraction, isActivating),

              // ── Scrollable Body with Title & 6 Category Cards ───────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      // Title
                      Text(
                        'What’s happening?',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 26,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      // Subtitle
                      Text(
                        'Choose the situation that matches your emergency.',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),

                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // ── 6 Category Rows ──────────────────────────────────
                      _buildCategoryRows(isActivating),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ── Bottom Banner: Auto SOS Info ────────────────────────────
              _buildBottomBanner(context, countdownValue, isActivating),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRows(bool isActivating) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CategoryCard(
                category: _emergencyCategories[0],
                isDisabled: isActivating,
                onTap: () => _onCategorySelected(context, _emergencyCategories[0].title),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CategoryCard(
                category: _emergencyCategories[1],
                isDisabled: isActivating,
                onTap: () => _onCategorySelected(context, _emergencyCategories[1].title),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CategoryCard(
                category: _emergencyCategories[2],
                isDisabled: isActivating,
                onTap: () => _onCategorySelected(context, _emergencyCategories[2].title),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CategoryCard(
                category: _emergencyCategories[3],
                isDisabled: isActivating,
                onTap: () => _onCategorySelected(context, _emergencyCategories[3].title),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CategoryCard(
                category: _emergencyCategories[4],
                isDisabled: isActivating,
                onTap: () => _onCategorySelected(context, _emergencyCategories[4].title),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CategoryCard(
                category: _emergencyCategories[5],
                isDisabled: isActivating,
                onTap: () => _onCategorySelected(context, _emergencyCategories[5].title),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopHeader(
    BuildContext context,
    int countdownValue,
    double progressFraction,
    bool isActivating,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // "Cancel / I'm Safe" Pill Button
          TextButton.icon(
            onPressed: isActivating ? null : () => _onUserSafe(context),
            icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.successGreenLight, size: 18),
            label: const Text(
              "I'm Safe",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),

          // 10s Countdown Circle Ring Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.sosPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.sosPrimary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    value: progressFraction,
                    strokeWidth: 2.2,
                    color: AppColors.sosPrimaryLight,
                    backgroundColor: Colors.white24,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isActivating ? 'Activating...' : '${countdownValue}s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBanner(
    BuildContext context,
    int countdownValue,
    bool isActivating,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141D2D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: SOS Circle Badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sosPrimary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.sosPrimary.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Center Text
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SOS will be activated automatically',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'If you don\'t select any option, SOS will call emergency services and alert contacts.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right: Red Siren Beacon Graphic
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.redAccent,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onCategorySelected(BuildContext context, String categoryTitle) async {
    await ref.read(emergencyControllerProvider.notifier).activateImmediately(category: categoryTitle);
  }

  Future<void> _onUserSafe(BuildContext context) async {
    if (mounted) setState(() => _showingSuccess = true);
    await ref.read(emergencyControllerProvider.notifier).markUserSafe();
  }
}

/// Category Card Widget for the 6 emergency options.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.isDisabled,
    required this.onTap,
  });

  final _EmergencyCategoryItem category;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        height: 135,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: category.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: category.gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // White circular icon badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.22),
              ),
              child: Icon(
                category.icon,
                color: Colors.white,
                size: 22,
              ),
            ),

            // Title and Description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  category.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}

/// Success overlay when user marks themselves safe.
class _SafeSuccessPage extends StatelessWidget {
  const _SafeSuccessPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.successGreen,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 80),
                SizedBox(height: 24),
                Text(
                  'You Are Safe!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28),
                ),
                SizedBox(height: 8),
                Text(
                  'Emergency trigger cancelled. Elly remains ready to protect you anytime.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
