/// vocal_biomarker_console.dart
///
/// Developer diagnostics widget for monitoring Phase 5 Vocal Biomarker Analysis.
/// Displays objective acoustic measurements, signal stability, DSP versioning, and latency.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/vocal_biomarker_state.dart';
import '../providers/vocal_biomarker_providers.dart';

class VocalBiomarkerConsole extends ConsumerWidget {
  const VocalBiomarkerConsole({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bioState = ref.watch(vocalBiomarkerControllerProvider);
    final telemetry = ref.watch(vocalBiomarkerTelemetryProvider);
    final config = ref.watch(vocalBiomarkerConfigProvider);
    final lastResult = bioState.lastResult;

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
                const Icon(Icons.graphic_eq_rounded, color: Colors.tealAccent, size: 20),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Vocal Biomarker Analysis',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(bioState.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(bioState.status)),
                  ),
                  child: Text(
                    bioState.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(bioState.status),
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
            _buildInfoRow(
              'DSP Engine',
              lastResult != null
                  ? '${lastResult.processingMethod} (${lastResult.dspVersion})'
                  : 'FEATURE_BASED_DSP (v1.0.0-dsp)',
            ),
            if (lastResult != null) ...[
              _buildInfoRow(
                'Voice Stability',
                '${(lastResult.voiceStability * 100).toStringAsFixed(1)}%',
                highlightColor: Colors.tealAccent,
              ),
              _buildInfoRow('Vocal Tension', '${(lastResult.vocalTension * 100).toStringAsFixed(1)}%'),
              _buildInfoRow('Speech Instability', '${(lastResult.speechInstability * 100).toStringAsFixed(1)}%'),
              _buildInfoRow('Breathing Irregularity', '${(lastResult.breathingIrregularity * 100).toStringAsFixed(1)}%'),
              _buildInfoRow('Pitch Var (F0)', '${lastResult.pitchVariability.toStringAsFixed(1)} Hz'),
              _buildInfoRow('Jitter / Shimmer', '${lastResult.jitter}% / ${lastResult.shimmer}%'),
              _buildInfoRow('HNR / Centroid', '${lastResult.harmonicsToNoiseRatio} dB / ${lastResult.spectralCentroid.toInt()} Hz'),
              _buildInfoRow('Confidence', '${(lastResult.confidence * 100).toStringAsFixed(1)}%'),
              _buildInfoRow('Processing Latency', '${lastResult.processingTimeMs} ms'),
              _buildInfoRow('Session ID', lastResult.sessionId),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Awaiting audio utterance for acoustic feature extraction...',
                  style: TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const Divider(color: Colors.white10, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Analyses: ${telemetry.analysisCount} | Failures: ${telemetry.failureCount}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'Max Latency: ${config.maxLatencyMs}ms',
                  style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.w500),
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
            width: 140,
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

  Color _getStatusColor(VocalBiomarkerStatus status) {
    switch (status) {
      case VocalBiomarkerStatus.idle:
        return Colors.grey;
      case VocalBiomarkerStatus.analyzing:
        return Colors.tealAccent;
      case VocalBiomarkerStatus.completed:
        return Colors.green;
      case VocalBiomarkerStatus.failed:
        return Colors.redAccent;
    }
  }
}
