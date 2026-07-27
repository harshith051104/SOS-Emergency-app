/// readiness_status_card.dart
///
/// Developer debug card rendering live ReadinessReport score, readiness level, and missing items.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/readiness/presentation/providers/readiness_providers.dart';

class ReadinessStatusCard extends ConsumerWidget {
  const ReadinessStatusCard({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(readinessControllerProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.fact_check_rounded, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Emergency Readiness',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${report.readinessScore}% ${report.readinessLevel.name.toUpperCase()}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ),

            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            children: [
              Text('Completed: ${report.completedRequirements.length}', style: const TextStyle(fontSize: 11)),
              Text('Missing: ${report.missingRequirements.length}', style: const TextStyle(fontSize: 11, color: Colors.amber)),
            ],
          ),
        ],
      ),
    );
  }
}
