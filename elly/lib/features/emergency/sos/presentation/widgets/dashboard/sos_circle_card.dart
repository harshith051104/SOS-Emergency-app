/// sos_circle_card.dart
///
/// Priority Emergency Responders Circle card redesigned to match the design reference image:
/// Displays header "SOS Circle (Who will be notified)", View All link, horizontal avatars with
/// green online indicators, priority level labels, and an Add Contact button card.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/sos_circle/presentation/providers/sos_circle_providers.dart';
import 'package:elly/features/emergency/sos_circle/domain/entities/emergency_contact.dart';

class SosCircleCard extends ConsumerWidget {
  const SosCircleCard({
    super.key,
    required this.isDark,
    required this.isActiveSos,
    required this.onViewAll,
  });

  final bool isDark;
  final bool isActiveSos;
  final VoidCallback onViewAll;

  static final List<Color> _priorityColors = [
    const Color(0xFFFF2E4D), // Priority 1 (Red)
    const Color(0xFFF97316), // Priority 2 (Orange)
    const Color(0xFF3B82F6), // Priority 3 (Blue)
    const Color(0xFFA855F7), // Priority 4 (Purple)
    const Color(0xFF22C55E), // Priority 5 (Green)
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circleState = ref.watch(sosCircleControllerProvider);
    final List<EmergencyContact> contacts = circleState.contacts;

    return LayoutBuilder(
      builder: (context, constraints) {
        // On phone (< 550px): show up to 5 contacts + Add Contact. On tablet (>= 550px): show all contacts.
        final isWideScreen = constraints.maxWidth >= 550;
        final maxVisible = isWideScreen ? contacts.length : 5;
        final displayContacts = contacts.take(maxVisible).toList();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'SOS Circle (Who will be notified)',
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
                          'View All',
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

              const SizedBox(height: 12),

              // Dynamic Contacts Row (Displays 5 on phone, all on tablet)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ...displayContacts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final contact = entry.value;
                    final priorityColor = _priorityColors[index % _priorityColors.length];
                    return Expanded(
                      child: _buildContactAvatar(contact, index + 1, priorityColor),
                    );
                  }),
                  Expanded(
                    child: _buildAddContactCard(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildContactAvatar(EmergencyContact contact, int priorityNum, Color priorityColor) {
    final displayName = contact.fullName.split(' ').first;
    final initial = contact.fullName.isNotEmpty ? contact.fullName[0].toUpperCase() : '?';

    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Circular Avatar Container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: priorityColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: priorityColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: priorityColor,
                    ),
                  ),
                ),
              ),

              // Green Online Dot Indicator (Top Right)
              Positioned(
                top: 1,
                right: 1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Name
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAddContactCard() {
    return GestureDetector(
      onTap: onViewAll,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                border: Border.all(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 26,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
            Text(
              'Contact',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
