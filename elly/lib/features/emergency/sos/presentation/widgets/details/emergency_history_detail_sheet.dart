/// emergency_history_detail_sheet.dart
///
/// Full emergency history and diagnostic test logs modal sheet.

library;

import 'package:flutter/material.dart';

class EmergencyHistoryDetailSheet extends StatelessWidget {
  const EmergencyHistoryDetailSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('EMERGENCY HISTORY LOGS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.orange)),
              const SizedBox(height: 12),
              _log('Routine Self-Test Cycle', 'Today, 19:45', 'Passed ✓', Colors.green),
              _log('Simulated SOS Monitoring Session', 'Yesterday, 14:20', 'Resolved (14 min)', Colors.blue),
            ],
          ),
        );
      },
    );
  }

  Widget _log(String title, String date, String status, Color color) {
    return ListTile(
      dense: true,
      leading: Icon(Icons.event_note_rounded, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
      subtitle: Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
