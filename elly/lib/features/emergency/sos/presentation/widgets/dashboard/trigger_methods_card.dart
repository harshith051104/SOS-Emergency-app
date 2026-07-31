/// trigger_methods_card.dart
///
/// Section "How SOS is Triggered" featuring 3 distinct cards (Manual, Voice, AI Detection):
///   - Manual: Mandatory & Always Active (No turning off)
///   - Voice: Interactive Voice Trigger On/Off + Edit Words
///   - AI Detection: Coming Soon badge

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import '../../providers/sos_trigger_config_provider.dart';
import 'package:elly/features/emergency/voice_trigger/presentation/widgets/wake_word_management_sheet.dart';

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
    final notifier = ref.read(sosTriggerConfigProvider.notifier);

    final cards = [
      _TriggerCardData(
        type: _TriggerType.manual,
        title: 'Manual',
        subtitle: 'SOS button, long press, device trigger',
        isEnabled: true,
        isMandatory: true,
        badgeText: 'MANDATORY',
        badgeColor: const Color(0xFFFF2E4D),
        icon: Icons.touch_app_rounded,
        iconBgColor: const Color(0xFFFFE5EA),
        iconColor: const Color(0xFFFF2E4D),
        onToggle: null,
      ),
      _TriggerCardData(
        type: _TriggerType.voice,
        title: 'Voice',
        subtitle: '"Help me", "Emergency", custom words',
        isEnabled: config.isVoiceTriggerEnabled,
        icon: Icons.mic_rounded,
        iconBgColor: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF9333EA),
        onToggle: (val) {
          notifier.toggleVoiceTrigger(val);
          if (val) {
            WakeWordManagementSheet.show(context);
          }
        },
      ),
      _TriggerCardData(
        type: _TriggerType.ai,
        title: 'AI Detection',
        subtitle: 'Auto-detects distress, falls & health risks',
        isEnabled: false,
        isComingSoon: true,
        badgeText: 'SOON',
        badgeColor: const Color(0xFFD97706),
        icon: Icons.psychology_rounded,
        iconBgColor: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
        onToggle: null,
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
                'How SOS is Triggered',
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
                mainAxisSize: MainAxisSize.min,
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

        // 3 Trigger Cards Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cards.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onViewAll,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.only(
                    right: index < cards.length - 1 ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.isEnabled
                          ? (isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1))
                          : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
                      width: item.isEnabled ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row: Icon + Switch/Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: item.iconBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              color: item.iconColor,
                              size: 14,
                            ),
                          ),

                          if (item.badgeText != null) ...[
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: item.badgeColor?.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: item.badgeColor?.withValues(alpha: 0.3) ?? Colors.transparent),
                                  ),
                                  child: Text(
                                    item.badgeText!,
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w900,
                                      color: item.badgeColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            // Compact On/Off Switch for Voice
                            SizedBox(
                              height: 24,
                              width: 38,
                              child: Transform.scale(
                                scale: 0.7,
                                child: Switch(
                                  value: item.isEnabled,
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: const Color(0xFF2E7D32),
                                  inactiveThumbColor: const Color(0xFF94A3B8),
                                  inactiveTrackColor: const Color(0xFFE2E8F0),
                                  onChanged: item.onToggle,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: item.isEnabled || item.isMandatory
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // CONDITIONAL INFORMATION DISPLAY:
                      // Information is displayed ONLY when feature is turned ON or MANDATORY!
                      if (item.isEnabled || item.isMandatory) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.type == _TriggerType.voice && item.isEnabled) ...[
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () {
                              WakeWordManagementSheet.show(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFD8B4FE)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_rounded, size: 10, color: Color(0xFF9333EA)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Edit Words',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF9333EA),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ] else ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.isComingSoon ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.isComingSoon ? 'Coming Soon' : 'Disabled',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: item.isComingSoon ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
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

enum _TriggerType { manual, voice, ai }

class _TriggerCardData {
  _TriggerCardData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.isEnabled,
    this.isMandatory = false,
    this.isComingSoon = false,
    this.badgeText,
    this.badgeColor,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.onToggle,
  });

  final _TriggerType type;
  final String title;
  final String subtitle;
  final bool isEnabled;
  final bool isMandatory;
  final bool isComingSoon;
  final String? badgeText;
  final Color? badgeColor;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final ValueChanged<bool>? onToggle;
}
