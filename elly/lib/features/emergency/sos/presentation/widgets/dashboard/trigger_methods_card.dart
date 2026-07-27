/// trigger_methods_card.dart
///
/// Compact Section 2 summary card watching `sosTriggerConfigProvider` to reflect
/// live ON/OFF status badges for Manual, Voice, Wake Word & Auto Detection triggers.

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
    final theme = Theme.of(context);

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
              Row(
                children: [
                  const Icon(Icons.flash_on_rounded, size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'HOW SOS SHOULD TRIGGER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  'Configure →',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _badge('Manual', true),
              const SizedBox(width: 6),
              _badge('Voice', config.isVoiceTriggerEnabled),
              const SizedBox(width: 6),
              _badge('Wake Word', config.isWakeWordEnabled),
              const SizedBox(width: 6),
              _badge('Auto Sensor', config.isAutoDetectionEnabled),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String name, bool enabled) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: enabled ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              enabled ? 'ON' : 'OFF',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: enabled ? Colors.green : Colors.grey,
              ),
            ),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
