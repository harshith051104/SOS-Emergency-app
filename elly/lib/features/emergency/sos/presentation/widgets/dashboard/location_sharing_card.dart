/// location_sharing_card.dart
///
/// Live Location Sharing status card.

library;

import 'package:flutter/material.dart';
import 'package:elly/core/theme/app_colors.dart';

class LocationSharingCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Location Sharing',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActiveSos ? 'Sharing  •  Updated 3s ago' : 'Enabled  •  Updates every 5s',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: onViewDetails,
            child: const Text(
              'Details →',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
