/// intent_developer_console.dart
///
/// Developer diagnostics widget for monitoring Emergency Intent classification status,
/// active intent results, confidence scores, latency, and configured thresholds.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/intent_state.dart';
import 'package:elly/features/emergency/intent_detection/presentation/providers/intent_providers.dart';

class IntentDeveloperConsole extends ConsumerWidget {
  const IntentDeveloperConsole({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intentState = ref.watch(intentControllerProvider);
    final telemetry = ref.watch(intentTelemetryProvider);
    final config = ref.watch(intentConfigProvider);
    final lastResult = intentState.lastResult;

    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_alt, color: Colors.amberAccent, size: 20),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Emergency Intent Detection',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(intentState.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(intentState.status)),
                  ),
                  child: Text(
                    intentState.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(intentState.status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Detector Engine', '${config.detectorType.name.toUpperCase()} (v${config.detectorVersion})'),
            _buildInfoRow(
              'Detected Intent',
              lastResult != null
                  ? '${lastResult.intent.name.toUpperCase()} (${(lastResult.confidence * 100).toStringAsFixed(1)}%)'
                  : 'Awaiting transcript analysis...',
              highlightColor: lastResult != null ? _getIntentColor(lastResult.intent) : null,
            ),
            if (lastResult != null) ...[
              _buildInfoRow('Matched Phrases', lastResult.matchedPhrases.isNotEmpty ? lastResult.matchedPhrases.join(', ') : 'None'),
              _buildInfoRow('Processing Latency', '${lastResult.processingTimeMs} ms'),
              _buildInfoRow('Session ID', lastResult.sessionId),
            ],
            const Divider(color: Colors.white10, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emergency: ${telemetry.classificationCounts[EmergencyIntent.emergency] ?? 0} | Possible: ${telemetry.classificationCounts[EmergencyIntent.possibleEmergency] ?? 0}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'Thresh: ${(config.emergencyThreshold * 100).toInt()}%',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlightColor ?? Colors.white,
                fontSize: 12,
                fontWeight: highlightColor != null ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(IntentStatus status) {
    switch (status) {
      case IntentStatus.idle:
        return Colors.grey;
      case IntentStatus.analyzing:
        return Colors.amber;
      case IntentStatus.completed:
        return Colors.green;
      case IntentStatus.error:
        return Colors.redAccent;
    }
  }

  Color _getIntentColor(EmergencyIntent intent) {
    switch (intent) {
      case EmergencyIntent.emergency:
        return AppColors.sosPrimary;
      case EmergencyIntent.possibleEmergency:
        return Colors.orangeAccent;
      case EmergencyIntent.nonEmergency:
        return Colors.greenAccent;
      case EmergencyIntent.unknown:
        return Colors.grey;
    }
  }
}
