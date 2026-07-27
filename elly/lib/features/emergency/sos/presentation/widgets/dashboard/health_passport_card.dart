/// health_passport_card.dart
///
/// Compact Emergency Health Passport summary card backed by Riverpod HealthPassportController.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/health_passport/presentation/providers/health_passport_providers.dart';

class HealthPassportCard extends ConsumerWidget {
  const HealthPassportCard({
    super.key,
    required this.isDark,
    required this.isActiveSos,
    required this.onViewAll,
  });

  final bool isDark;
  final bool isActiveSos;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final passportState = ref.watch(healthPassportControllerProvider);
    final passport = passportState.passport;
    final profile = passport?.profile;

    final bloodGroup = profile?.bloodGroup ?? 'O+';
    final allergiesStr = profile != null && profile.allergies.isNotEmpty
        ? 'Allergies: ${profile.allergies.first}'
        : 'No Known Allergies';
    final conditionsStr = profile != null && profile.chronicConditions.isNotEmpty
        ? 'Conditions: ${profile.chronicConditions.first}'
        : 'No Chronic Conditions';
    final score = passport?.completenessScore ?? 90;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.medical_information_rounded, size: 18, color: Colors.purple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'HEALTH PASSPORT ($score% COMPLETE)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  'Manage →',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _badge('Blood: $bloodGroup', Colors.red),
              _badge(allergiesStr, Colors.amber),
              _badge(conditionsStr, Colors.blue),
              if (isActiveSos) _badge('Attached to Context ✓', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

}
