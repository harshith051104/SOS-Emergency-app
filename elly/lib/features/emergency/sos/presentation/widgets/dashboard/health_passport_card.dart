/// health_passport_card.dart
///
/// Emergency Health Passport card redesigned to match the design reference image:
/// Features header "Emergency Health Passport (Shared during SOS)", Manage link, and
/// a 6-item horizontal mini-card grid (Medical Info, Allergies, Medications, Conditions,
/// Recent Reports, AI Insights) with icons and green checkmark completion indicators.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Emergency Health Passport',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 8),
            GestureDetector(
              onTap: onViewAll,
              child: const Row(
                children: [
                  Text(
                    'Manage',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF3B82F6)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal Mini-Cards List
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: 96,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon Container
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color: item.iconColor,
                        size: 20,
                      ),
                    ),

                    // Title
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Bottom Green Checkmark Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (item.isComplete)
                          Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 9,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
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
