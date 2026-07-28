/// location_sharing_card.dart
///
/// Live Location Sharing card redesigned to match the design reference image:
/// Features header "Live Location Sharing", status pill "Sharing enabled",
/// pin icon in soft pink circle, description, and an active toggle switch.

library;

import 'package:flutter/material.dart';
import 'package:elly/core/theme/app_colors.dart';

class LocationSharingCard extends StatefulWidget {
  const LocationSharingCard({
    super.key,
    required this.isDark,
    required this.isActiveSos,
    required this.onViewDetails,
  });

  final bool isDark;
  final bool isActiveSos;
  final VoidCallback onViewDetails;

  @override
  State<LocationSharingCard> createState() => _LocationSharingCardState();
}

class _LocationSharingCardState extends State<LocationSharingCard> {
  bool _isSharingEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Live Location Sharing',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.near_me_rounded, size: 14, color: Color(0xFF16A34A)),
                const SizedBox(width: 4),
                Text(
                  _isSharingEnabled ? 'Sharing enabled' : 'Sharing disabled',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isSharingEnabled ? const Color(0xFF16A34A) : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Main Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),

            border: Border.all(
              color: widget.isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left: Pin Icon in soft pink circle
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE5EA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFFFF2E4D),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Middle Column: Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live location will be shared during emergency',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.isActiveSos ? 'Sharing live • Updating every 3s' : 'Updates every 5 seconds',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDark ? Colors.white60 : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Right: Coral Red Toggle Switch
              Switch.adaptive(
                value: _isSharingEnabled,
                activeTrackColor: const Color(0xFFFF2E4D),
                onChanged: (val) {

                  setState(() => _isSharingEnabled = val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
