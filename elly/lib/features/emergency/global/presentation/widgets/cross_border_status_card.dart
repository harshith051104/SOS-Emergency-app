/// cross_border_status_card.dart
///
/// Developer debug & telemetry preview card rendering live CrossBorderContext metrics.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/global/presentation/providers/global_providers.dart';

class CrossBorderStatusCard extends ConsumerWidget {
  const CrossBorderStatusCard({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalCtx = ref.watch(crossBorderControllerProvider);
    final profile = globalCtx.currentCountry;
    final detection = globalCtx.lastDetectionResult;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: globalCtx.isRoaming ? Colors.amber.withValues(alpha: 0.5) : Colors.blue.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (globalCtx.isRoaming ? Colors.amber : Colors.blue).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.public_rounded, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Cross-Border Engine (${profile.countryCode})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (globalCtx.isRoaming ? Colors.amber : Colors.blue).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  globalCtx.isRoaming ? 'ROAMING' : 'HOME',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: globalCtx.isRoaming ? Colors.amber.shade900 : Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildMetric('Country', '${profile.countryName} (${profile.countryCode})'),
              _buildMetric('Detection', '${detection?.source.name ?? "Locale"} (${((detection?.confidence ?? 0.6) * 100).toInt()}%)'),
              _buildMetric('Medical / Police / Fire', '${profile.medicalNumber} / ${profile.policeNumber} / ${profile.fireNumber}'),
              _buildMetric('Language', profile.defaultLanguage),
              _buildMetric('TimeZone', profile.timeZone),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
