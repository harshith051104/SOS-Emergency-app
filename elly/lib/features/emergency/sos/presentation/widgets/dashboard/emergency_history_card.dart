/// emergency_history_card.dart
///
/// Emergency history and recent activity log card.

library;

import 'package:flutter/material.dart';
import 'package:elly/core/theme/app_colors.dart';

class EmergencyHistoryCard extends StatelessWidget {
  const EmergencyHistoryCard({
    super.key,
    required this.isDark,
    required this.onViewAll,
  });

  final bool isDark;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
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
                  const Icon(Icons.history_rounded, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'EMERGENCY HISTORY',
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
                  'View All →',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Last Test: Today, 19:45', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text('Status: Passed ✓', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }
}
