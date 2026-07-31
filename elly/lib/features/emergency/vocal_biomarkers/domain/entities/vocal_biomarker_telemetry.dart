/// vocal_biomarker_telemetry.dart
///
/// Telemetry metrics for monitoring Vocal Biomarker Analysis performance.

library;

import 'package:flutter/foundation.dart';

@immutable
class VocalBiomarkerTelemetry {
  const VocalBiomarkerTelemetry({
    this.averageLatency = 0.0,
    this.averageStability = 0.0,
    this.averageConfidence = 0.0,
    this.analysisCount = 0,
    this.failureCount = 0,
  });

  final double averageLatency;
  final double averageStability;
  final double averageConfidence;
  final int analysisCount;
  final int failureCount;

  VocalBiomarkerTelemetry recordSuccess({
    required double latencyMs,
    required double stability,
    required double confidence,
  }) {
    final nextCount = analysisCount + 1;
    final nextAvgLatency = ((averageLatency * analysisCount) + latencyMs) / nextCount;
    final nextAvgStability = ((averageStability * analysisCount) + stability) / nextCount;
    final nextAvgConfidence = ((averageConfidence * analysisCount) + confidence) / nextCount;

    return VocalBiomarkerTelemetry(
      averageLatency: nextAvgLatency,
      averageStability: nextAvgStability,
      averageConfidence: nextAvgConfidence,
      analysisCount: nextCount,
      failureCount: failureCount,
    );
  }

  VocalBiomarkerTelemetry recordFailure() {
    return VocalBiomarkerTelemetry(
      averageLatency: averageLatency,
      averageStability: averageStability,
      averageConfidence: averageConfidence,
      analysisCount: analysisCount,
      failureCount: failureCount + 1,
    );
  }
}
