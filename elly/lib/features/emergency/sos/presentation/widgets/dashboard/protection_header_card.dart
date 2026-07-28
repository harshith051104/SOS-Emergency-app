/// protection_header_card.dart
///
/// Top Emergency Protection Card matching design reference:
/// Premium Coral/Red gradient background, white SOS shield icon, ACTIVE status pill,
/// and Test SOS action button.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';

class ProtectionHeaderCard extends ConsumerWidget {
  const ProtectionHeaderCard({
    super.key,
    required this.isDark,
    required this.readinessScore,
    required this.isActiveSos,
    this.elapsedFormatted,
    required this.onTestSos,
  });

  final bool isDark;
  final int readinessScore;
  final bool isActiveSos;
  final String? elapsedFormatted;
  final VoidCallback onTestSos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isActiveSos) {
      return SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onTestSos,
          icon: const Icon(Icons.stop_circle_rounded, color: Colors.white, size: 22),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'END EMERGENCY SESSION (${elapsedFormatted ?? "LIVE"})',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                letterSpacing: 0.8,
                color: Colors.white,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sosPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            elevation: 6,
            shadowColor: AppColors.sosPrimary.withValues(alpha: 0.5),
          ),
        ),
      );
    }


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF526C), Color(0xFFFF2E4D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2E4D).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: SOS Shield Icon
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.shield_rounded,
                    color: Color(0xFFFF2E4D),
                    size: 42,
                  ),

                  Text(
                    'SOS',

                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Middle Column: Title, Active Status, Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Emergency Protection',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'ELLY is always ready to protect you.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right: Test SOS Pill Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTestSos,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monitor_heart_outlined,
                      color: Color(0xFFFF2E4D),
                      size: 16,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Test SOS',
                      style: TextStyle(
                        color: Color(0xFFFF2E4D),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
