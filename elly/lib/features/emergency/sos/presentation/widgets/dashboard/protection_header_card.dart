/// protection_header_card.dart
///
/// Top Emergency Protection Card featuring:
///   - Premium Coral/Red gradient background with white SOS shield
///   - ACTIVE protection status
///   - Integrated Location Sharing toggle with Location Pin Icon 📍
///   - Test SOS / End Emergency action button

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';

class ProtectionHeaderCard extends ConsumerStatefulWidget {
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
  ConsumerState<ProtectionHeaderCard> createState() => _ProtectionHeaderCardState();
}

class _ProtectionHeaderCardState extends ConsumerState<ProtectionHeaderCard> {
  bool _isLocationSharingEnabled = true;

  @override
  Widget build(BuildContext context) {
    if (widget.isActiveSos) {
      return SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: widget.onTestSos,
          icon: const Icon(Icons.stop_circle_rounded, color: Colors.white, size: 22),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'END EMERGENCY SESSION (${widget.elapsedFormatted ?? "LIVE"})',
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
            width: 48,
            height: 48,
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
                    size: 40,
                  ),
                  Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 9.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

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
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
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
                        size: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'ELLY is always ready to protect you.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right Side: Location Sharing Toggle Widget with Location Icon 📍
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: _isLocationSharingEnabled ? const Color(0xFF4ADE80) : Colors.white60,
                      size: 15,
                    ),
                    const SizedBox(width: 2),
                    SizedBox(
                      height: 20,
                      width: 32,
                      child: Transform.scale(
                        scale: 0.65,
                        child: Switch(
                          value: _isLocationSharingEnabled,
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF2E7D32),
                          inactiveThumbColor: Colors.white70,
                          inactiveTrackColor: Colors.white30,
                          onChanged: (val) {
                            setState(() {
                              _isLocationSharingEnabled = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _isLocationSharingEnabled ? 'GPS Live' : 'GPS Off',
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
