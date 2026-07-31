/// health_passport_card.dart
///
/// Emergency Health Passport card redesigned to match the design reference image:
/// Features header "Emergency Health Passport (Shared during SOS)", Manage link, and
/// a 6-item horizontal mini-card grid (Medical Info, Allergies, Medications, Conditions,
/// Recent Reports, AI Insights) with icons and green checkmark completion indicators.

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
    final passportState = ref.watch(healthPassportControllerProvider);
    final passport = passportState.passport;
    final profile = passport?.profile;

    final bloodGroup = profile?.bloodGroup ?? 'O+';
    final hasAllergies = profile != null && profile.allergies.isNotEmpty;
    final hasConditions = profile != null && profile.chronicConditions.isNotEmpty;

    final items = [
      _PassportItemData(
        title: 'Medical Info',
        subtitle: 'Blood: $bloodGroup',
        icon: Icons.medical_services_outlined,
        bgColor: const Color(0xFFFFE5EA),
        iconColor: const Color(0xFFFF2E4D),
        isComplete: true,
      ),
      _PassportItemData(
        title: 'Allergies',
        subtitle: hasAllergies ? profile.allergies.first : 'Penicillin',
        icon: Icons.vaccines_outlined,
        bgColor: const Color(0xFFFFF7ED),
        iconColor: const Color(0xFFEA580C),
        isComplete: true,
      ),
      _PassportItemData(
        title: 'Medications',
        subtitle: '2 Active',
        icon: Icons.medication_outlined,
        bgColor: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0284C7),
        isComplete: true,
      ),
      _PassportItemData(
        title: 'Conditions',
        subtitle: hasConditions ? profile.chronicConditions.first : 'Asthma',
        icon: Icons.favorite_border_rounded,
        bgColor: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF9333EA),
        isComplete: true,
      ),
      _PassportItemData(
        title: 'Recent Reports',
        subtitle: '1 Attached',
        icon: Icons.description_outlined,
        bgColor: const Color(0xFFF0FDFA),
        iconColor: const Color(0xFF0D9488),
        isComplete: true,
      ),
      _PassportItemData(
        title: 'AI Insights',
        subtitle: 'Updated',
        icon: Icons.psychology_outlined,
        bgColor: const Color(0xFFFFE5EA),
        iconColor: const Color(0xFFFF2E4D),
        isComplete: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Emergency Health Passport',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 6),
            GestureDetector(
              onTap: onViewAll,
              child: const Row(
                children: [
                  Text(
                    'Manage',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 15, color: Color(0xFF3B82F6)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Static 6-Column Mini-Cards Row (All 6 displayed at once matching reference image)
        Row(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Expanded(
              child: GestureDetector(
                onTap: onViewAll,
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < items.length - 1 ? 6 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon Container
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: item.bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          color: item.iconColor,
                          size: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Title Label
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Green Checkmark Indicator
                      const Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: Color(0xFF22C55E),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }


}

class _PassportItemData {
  _PassportItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.isComplete,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final bool isComplete;
}
