/// offline_resilience_status_card.dart
///
/// Developer debug & telemetry preview card rendering live OfflineHealthReport resilience metrics.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/offline_resilience/presentation/providers/resilience_providers.dart';

class OfflineResilienceStatusCard extends ConsumerWidget {
  const OfflineResilienceStatusCard({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(offlineResilienceControllerProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (report?.isCorruptionDetected ?? false) ? Colors.red.withValues(alpha: 0.5) : Colors.teal.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ((report?.isCorruptionDetected ?? false) ? Colors.red : Colors.teal).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
                    Icon(Icons.health_and_safety_rounded, color: Colors.teal, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Offline Resilience & Survivability',
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
                  color: Colors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report != null ? 'HEALTHY' : 'INITIALIZING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildMetric('Queue Health', '${report?.queuedPackets ?? 0} queued'),
              _buildMetric('Queue Size', '${((report?.queueSizeBytes ?? 0) / 1024).toStringAsFixed(1)} KB'),
              _buildMetric('Storage Policy', report?.storagePolicy.name.toUpperCase() ?? 'NORMAL'),
              _buildMetric('Battery Policy', report?.batteryPolicy.name.toUpperCase() ?? 'NORMAL'),
              _buildMetric('Checksum Integrity', (report?.isCorruptionDetected ?? false) ? 'Corrupted Repaired' : '100% Valid'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
