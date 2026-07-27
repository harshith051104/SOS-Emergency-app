/// readiness_matrix_card.dart
///
/// System readiness diagnostic matrix card with color-independent accessibility labels.

library;

import 'package:flutter/material.dart';
import 'package:elly/core/theme/app_colors.dart';

class ReadinessMatrixCard extends StatelessWidget {
  const ReadinessMatrixCard({
    super.key,
    required this.isDark,
    required this.onViewDetails,
  });

  final bool isDark;
  final VoidCallback onViewDetails;

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
                  const Icon(Icons.verified_user_rounded, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'EMERGENCY READINESS',
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
                onTap: onViewDetails,
                child: const Text(
                  'Details →',
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
              _checkItem('GPS', true),
              _checkItem('Internet', true),
              _checkItem('SMS', true),
              _checkItem('Phone', true),
              _checkItem('Mic', true),
              _checkItem('Battery Opt', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkItem(String name, bool isReady) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isReady ? Colors.green.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isReady ? Colors.green : Colors.amber),
      ),
      child: Text(
        '${isReady ? "✓" : "⚠"} $name',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isReady ? Colors.green : Colors.amber.shade900,
        ),
      ),
    );
  }
}
