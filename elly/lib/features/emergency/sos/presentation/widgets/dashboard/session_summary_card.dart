/// session_summary_card.dart
///
/// Post-emergency session summary card providing closure metrics.

library;

import 'package:flutter/material.dart';
import 'package:elly/core/theme/app_colors.dart';

class SessionSummaryCard extends StatelessWidget {
  const SessionSummaryCard({
    super.key,
    required this.isDark,
    required this.durationFormatted,
    required this.packetsSent,
    required this.respondersReached,
    required this.onDone,
  });

  final bool isDark;
  final String durationFormatted;
  final int packetsSent;
  final int respondersReached;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
              SizedBox(width: 10),
              Text(
                'EMERGENCY RESOLVED',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.green, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statTile('Duration', durationFormatted, isDark),
              _statTile('Responders', '$respondersReached', isDark),
              _statTile('Packets Sent', '$packetsSent', isDark),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onDone,
            child: const Text('DONE & RETURN TO PROTECTED MODE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
