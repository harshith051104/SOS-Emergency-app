/// emergency_type_sheet.dart
///
/// Non-blocking post-activation emergency category sheet.

library;

import 'package:flutter/material.dart';
import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/sos/domain/enums/emergency_type.dart';

class EmergencyTypeSheet extends StatelessWidget {
  const EmergencyTypeSheet({
    super.key,
    required this.onSelectType,
    required this.onSkip,
  });

  final ValueChanged<EmergencyType> onSelectType;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Help Us Respond Faster',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select emergency category below or tap Skip. SOS is ALREADY ACTIVE in the background.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _typeChip(context, 'Manual SOS', Icons.pan_tool_rounded, EmergencyType.manual),
              _typeChip(context, 'Voice Trigger', Icons.mic_rounded, EmergencyType.voice),
              _typeChip(context, 'AI Automatic', Icons.auto_awesome_rounded, EmergencyType.automatic),
              _typeChip(context, 'Wearable Watch', Icons.watch_rounded, EmergencyType.wearable),
              _typeChip(context, 'Fall Detection', Icons.personal_injury_rounded, EmergencyType.fallDetection),
              _typeChip(context, 'Health Alert', Icons.favorite_rounded, EmergencyType.healthAlert),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onSkip,
              child: const Text('SKIP & CONTINUE →', style: TextStyle(color: AppColors.sosPrimary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(BuildContext context, String label, IconData icon, EmergencyType type) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: Colors.amber),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () => onSelectType(type),
    );
  }
}
