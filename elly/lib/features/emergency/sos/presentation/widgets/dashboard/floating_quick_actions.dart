/// floating_quick_actions.dart
///
/// Bottom Floating Actions Bar redesigned to match design reference spec:
/// Contains "Call Emergency" and "Message SOS Circle" action buttons with zero Activate SOS button,
/// followed by the ELLY AI Guardian sub-caption.

library;

import 'package:flutter/material.dart';

class FloatingQuickActionsBar extends StatelessWidget {
  const FloatingQuickActionsBar({
    super.key,
    required this.isDark,
    required this.onCallEmergency,
    required this.onMessageCircle,
    this.onActivateSos,
  });

  final bool isDark;
  final VoidCallback onCallEmergency;
  final VoidCallback onMessageCircle;
  final VoidCallback? onActivateSos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Action Button (Call Emergency - Automated SMS & Data dispatches on SOS trigger)
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCallEmergency,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF526C), Color(0xFFFF2E4D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2E4D).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sos_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Need Help',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),



          const SizedBox(height: 10),

          // Sub-caption
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 13,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                "ELLY is your AI Guardian. We're always here for you.",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
