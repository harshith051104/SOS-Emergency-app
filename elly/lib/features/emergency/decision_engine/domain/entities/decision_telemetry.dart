/// decision_telemetry.dart
///
/// Telemetry metrics for tracking Decision Engine performance.

library;

import 'package:flutter/foundation.dart';

@immutable
class DecisionTelemetry {
  const DecisionTelemetry({
    this.evaluationCount = 0,
    this.averageLatency = 0.0,
    this.averageConfidence = 0.0,
    this.averageEvidenceCount = 0.0,
    this.failureCount = 0,
  });

  final int evaluationCount;
  final double averageLatency;
  final double averageConfidence;
  final double averageEvidenceCount;
  final int failureCount;

  DecisionTelemetry recordSuccess({
    required double latencyMs,
    required double confidence,
    required int evidenceCount,
  }) {
    final nextCount = evaluationCount + 1;
    final nextAvgLatency = ((averageLatency * evaluationCount) + latencyMs) / nextCount;
    final nextAvgConfidence = ((averageConfidence * evaluationCount) + confidence) / nextCount;
    final nextAvgEvidenceCount = ((averageEvidenceCount * evaluationCount) + evidenceCount) / nextCount;

    return DecisionTelemetry(
      evaluationCount: nextCount,
      averageLatency: nextAvgLatency,
      averageConfidence: nextAvgConfidence,
      averageEvidenceCount: nextAvgEvidenceCount,
      failureCount: failureCount,
    );
  }

  DecisionTelemetry recordFailure() {
    return DecisionTelemetry(
      evaluationCount: evaluationCount,
      averageLatency: averageLatency,
      averageConfidence: averageConfidence,
      averageEvidenceCount: averageEvidenceCount,
      failureCount: failureCount + 1,
    );
  }
}
