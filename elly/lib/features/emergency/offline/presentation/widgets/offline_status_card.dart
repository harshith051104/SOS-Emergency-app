/// offline_status_card.dart
///
/// Developer debug & status card rendering live offline engine metrics (connectivity, queue size, retry count, last sync).

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';
import 'package:elly/features/emergency/offline/domain/entities/connectivity_state.dart';

class OfflineStatusCard extends ConsumerWidget {
  const OfflineStatusCard({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityService = ref.watch(connectivityServiceProvider);
    final queueService = ref.watch(offlineQueueProvider);

    final connState = connectivityService.currentState;
    final pendingCount = queueService.pendingPackets.length;
    final totalCount = queueService.allPackets.length;

    final isOffline = connState == ConnectivityState.offline || connState == ConnectivityState.airplaneMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOffline ? Colors.orange.withValues(alpha: 0.5) : Colors.green.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOffline ? Colors.orange : Colors.green).withValues(alpha: 0.05),
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
              Row(
                children: [
                  Icon(
                    isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                    color: isOffline ? Colors.orange : Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Offline Mode Engine',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isOffline ? Colors.orange : Colors.green).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  connState.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOffline ? Colors.orange.shade800 : Colors.green.shade800,
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
              _buildMetric('Queue Size', '$totalCount packets'),
              _buildMetric('Pending Uploads', '$pendingCount packets'),
              _buildMetric('Connectivity', connState.name),
              _buildMetric('Persistence', 'SharedPreferences JSON'),
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
