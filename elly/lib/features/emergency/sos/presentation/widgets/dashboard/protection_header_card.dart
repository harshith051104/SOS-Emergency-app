/// protection_header_card.dart
///
/// Top header card showing protection status, readiness score, live telemetry stats, and END EMERGENCY SESSION when active.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/telemetry/presentation/providers/telemetry_providers.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';
import 'package:elly/features/emergency/offline/domain/entities/network_state.dart';

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
    final theme = Theme.of(context);
    final telemetryPoint = ref.watch(latestTelemetryPointProvider);

    // Swap: Place END EMERGENCY SESSION button at top when active
    if (isActiveSos) {
      return SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          onPressed: onTestSos,
          icon: const Icon(Icons.stop_circle_rounded, color: Colors.white, size: 26),
          label: const Text(
            'END EMERGENCY SESSION',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sosPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 6,
            shadowColor: AppColors.sosPrimary.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final latLngStr = telemetryPoint != null
        ? '${telemetryPoint.latitude.toStringAsFixed(4)}, ${telemetryPoint.longitude.toStringAsFixed(4)}'
        : 'GPS Active • Lat/Lng Attached';
    final accuracyStr = telemetryPoint != null ? '±${telemetryPoint.accuracy.toStringAsFixed(0)}m' : '±8m';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ELLY Protection Active',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 11, color: Colors.blue),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '$latLngStr ($accuracyStr)',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Network Status Badge & Test SOS Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final netState = ref.watch(networkStateProvider);
                  final isOffline = netState == NetworkState.offline;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOffline ? Colors.amber.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOffline ? Colors.amber : Colors.green,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                          size: 11,
                          color: isOffline ? Colors.amber.shade800 : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOffline ? 'OFFLINE' : 'ONLINE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isOffline ? Colors.amber.shade800 : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 28,
                child: OutlinedButton(
                  onPressed: onTestSos,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.sosPrimary.withValues(alpha: 0.5)),
                    foregroundColor: AppColors.sosPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'TEST SOS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 9.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

  }

}
