/// trigger_methods_card.dart
///
/// Section "How SOS is Triggered" redesigned to match the design reference image:
/// Features 3 distinct cards (Manual, Voice, AI Detection) with icons, ON status chips,
/// descriptions, and arrow action buttons.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import '../../providers/sos_trigger_config_provider.dart';

class TriggerMethodsCard extends ConsumerWidget {
  const TriggerMethodsCard({
    super.key,
    required this.isDark,
    required this.onViewAll,
  });

  final bool isDark;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(sosTriggerConfigProvider);

    final cards = [
      _TriggerCardData(
        title: 'Manual',
        subtitle: 'SOS button, long press, device trigger',
        isEnabled: true,
        icon: Icons.touch_app_rounded,
        iconBgColor: const Color(0xFFFFE5EA),
        iconColor: const Color(0xFFFF2E4D),
      ),
      _TriggerCardData(
        title: 'Voice',
        subtitle: '"Help me", "Emergency", "I can\'t breathe" & more',
        isEnabled: config.isVoiceTriggerEnabled,
        icon: Icons.mic_rounded,
        iconBgColor: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF9333EA),
      ),
      _TriggerCardData(
        title: 'AI Detection',
        subtitle: 'Auto-detects distress, falls, abnormal signs & health risks',
        isEnabled: config.isAutoDetectionEnabled,
        icon: Icons.psychology_rounded,
        iconBgColor: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0284C7),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'How SOS is Triggered',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: const Row(
                children: [
                  Text(
                    'Manage',
                    style: TextStyle(
                      fontSize: 13,
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

        // Horizontal Scrollable Cards List
        SizedBox(
          height: 142,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = cards[index];
              return Container(
                width: 210,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(22),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Icon + Title + ON/OFF Chip
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.iconBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            color: item.iconColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.isEnabled
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: item.isEnabled
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Text(
                            item.isEnabled ? 'ON' : 'OFF',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: item.isEnabled
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Subtitle Text
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Bottom Right Arrow Circle
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
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

class _TriggerCardData {
  _TriggerCardData({
    required this.title,
    required this.subtitle,
    required this.isEnabled,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final bool isEnabled;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
}
