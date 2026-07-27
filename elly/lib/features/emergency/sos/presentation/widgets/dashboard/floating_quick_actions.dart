/// floating_quick_actions.dart
///
/// Floating thumb-zone quick actions bar.

library;

import 'package:flutter/material.dart';
import 'package:elly/core/theme/app_colors.dart';

class FloatingQuickActionsBar extends StatelessWidget {
  const FloatingQuickActionsBar({
    super.key,
    required this.isDark,
    required this.onCallEmergency,
    required this.onActivateSos,
    required this.onMessageCircle,
  });

  final bool isDark;
  final VoidCallback onCallEmergency;
  final VoidCallback onActivateSos;
  final VoidCallback onMessageCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Direct Emergency Call Button (112)
          InkWell(
            onTap: onCallEmergency,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_in_talk_rounded, color: Colors.redAccent, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'CALL 112',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Center Activate SOS Button
          ElevatedButton.icon(
            icon: const Icon(Icons.sos_rounded, size: 18, color: Colors.white),
            label: const Text('SOS TRIGGER'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 4,
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8),
            ),
            onPressed: onActivateSos,
          ),

          // 3. Message SOS Circle Contacts
          InkWell(
            onTap: onMessageCircle,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_alt_rounded, color: Colors.blueAccent, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'CIRCLE',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

