/// speaker_verification_console.dart
///
/// Developer diagnostics widget for monitoring Phase 4 Speaker Verification status,
/// active match results, similarity confidence %, latency, and profile metadata.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_state.dart';
import 'package:elly/features/emergency/speaker_verification/presentation/providers/speaker_verification_providers.dart';

class SpeakerVerificationConsole extends ConsumerWidget {
  const SpeakerVerificationConsole({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spkState = ref.watch(speakerVerificationControllerProvider);
    final telemetry = ref.watch(speakerVerificationTelemetryProvider);
    final config = ref.watch(speakerVerificationConfigProvider);
    final lastResult = spkState.lastResult;
    final activeProfile = spkState.activeProfile;

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
                const Icon(Icons.record_voice_over_rounded, color: Colors.cyan, size: 20),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Speaker Verification',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(spkState.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(spkState.status)),
                  ),
                  child: Text(
                    spkState.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(spkState.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Engine Method', '${config.verifierType.name.toUpperCase()} (${config.embeddingVersion})'),
            _buildInfoRow('Active Profile', activeProfile?.displayName ?? 'Device Owner (Primary)'),
            _buildInfoRow(
              'Speaker Match',
              lastResult != null
                  ? (lastResult.match ? 'VERIFIED MATCH (OWNER)' : 'UNMATCHED SPEAKER')
                  : 'Awaiting audio utterance...',
              highlightColor: lastResult != null ? (lastResult.match ? Colors.greenAccent : Colors.orangeAccent) : null,
            ),
            if (lastResult != null) ...[
              _buildInfoRow('Similarity Score', '${(lastResult.confidence * 100).toStringAsFixed(1)}%'),
              _buildInfoRow('Processing Latency', '${lastResult.processingTimeMs} ms'),
              _buildInfoRow('Session ID', lastResult.sessionId),
            ],
            const Divider(color: Colors.white10, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Matches: ${telemetry.successfulMatches} | Failed: ${telemetry.failedMatches}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'Thresh: ${(config.similarityThreshold * 100).toInt()}%',
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w500),
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

  Color _getStatusColor(SpeakerVerificationStatus status) {
    switch (status) {
      case SpeakerVerificationStatus.idle:
        return Colors.grey;
      case SpeakerVerificationStatus.verifying:
        return Colors.cyan;
      case SpeakerVerificationStatus.completed:
        return Colors.green;
      case SpeakerVerificationStatus.failed:
        return Colors.redAccent;
    }
  }
}
