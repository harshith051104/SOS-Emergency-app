/// communication_status_card.dart
///
/// Developer debug card rendering live active communication channels, last delivery, and fallback status.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/communication/presentation/providers/communication_providers.dart';

class CommunicationStatusCard extends ConsumerWidget {
  const CommunicationStatusCard({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(communicationControllerProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.indigo.withValues(alpha: 0.3),
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
                    Icon(Icons.cell_tower_rounded, color: Colors.indigo, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Intelligent Communication Engine',
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
                  color: Colors.indigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result != null ? result.status.name.toUpperCase() : 'READY',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            children: [
              const Text('Channels: Push, SMS, Call, Email', style: TextStyle(fontSize: 11)),

              Text('Last Used: ${result?.channelUsed ?? "None"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Text('Retry Count: ${result?.retryCount ?? 0}', style: const TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
