/// current_status_card.dart
///
/// Dedicated Heartbeat card showing system health status.

library;

import 'package:flutter/material.dart';
import 'package:elly/core/theme/app_colors.dart';

class CurrentStatusCard extends StatelessWidget {
  const CurrentStatusCard({
    super.key,
    required this.isDark,
    required this.isActiveSos,
    this.respondersCount = 3,
  });

  final bool isDark;
  final bool isActiveSos;
  final int respondersCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActiveSos ? AppColors.sosPrimary : theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isActiveSos ? Icons.warning_amber_rounded : Icons.favorite_rounded,
                    color: isActiveSos ? AppColors.sosPrimary : Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CURRENT SYSTEM STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
              Text(
                isActiveSos ? 'DISPATCHING' : 'READY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActiveSos ? AppColors.sosPrimary : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildBadge('Heartbeat', 'Active', Colors.green),
              const SizedBox(width: 8),
              _buildBadge('Responders', '$respondersCount Ready', Colors.blue),
              const SizedBox(width: 8),
              _buildBadge('Channel', 'Internet', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String key, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            Text(key, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
