/// emergency_data_packet_card.dart
///
/// Developer debug & telemetry preview card rendering live EmergencyDataPacket summary metrics,
/// packet checksum, sequence number, and status.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/packet/presentation/providers/packet_providers.dart';

class EmergencyDataPacketCard extends ConsumerWidget {
  const EmergencyDataPacketCard({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packet = ref.watch(emergencyDataPacketProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.inventory_2_rounded, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Smart Emergency Data Packet',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${packet.sequenceNumber}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'v${packet.packetVersion}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Metadata Grid
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildMetric('Packet ID', packet.packetId),
              _buildMetric('Checksum', packet.packetChecksum),
              _buildMetric('Session ID', packet.sessionId),
              _buildMetric('User', '${packet.name} (${packet.bloodGroup})'),
              _buildMetric('Location', '${packet.latitude.toStringAsFixed(4)}, ${packet.longitude.toStringAsFixed(4)}'),
              _buildMetric('Timeline Events', '${packet.totalEvents} recorded'),
              _buildMetric('Network', packet.deviceInfo.networkState.toUpperCase()),
              _buildMetric('Severity', packet.currentSeverity),
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
