/// speaker_verification_telemetry.dart
///
/// Telemetry model tracking verification latency, match ratios, false accept/reject counts, and similarity scores.

library;

import 'package:flutter/foundation.dart';

@immutable
class SpeakerVerificationTelemetry {
  const SpeakerVerificationTelemetry({
    this.verificationCount = 0,
    this.successfulMatches = 0,
    this.failedMatches = 0,
    this.averageLatencyMs = 0,
    this.averageConfidence = 0.0,
    this.averageSimilarity = 0.0,
    this.falseRejectCount = 0,
    this.falseAcceptCount = 0,
  });

  final int verificationCount;
  final int successfulMatches;
  final int failedMatches;
  final int averageLatencyMs;
  final double averageConfidence;
  final double averageSimilarity;
  final int falseRejectCount;
  final int falseAcceptCount;

  SpeakerVerificationTelemetry copyWith({
    int? verificationCount,
    int? successfulMatches,
    int? failedMatches,
    int? averageLatencyMs,
    double? averageConfidence,
    double? averageSimilarity,
    int? falseRejectCount,
    int? falseAcceptCount,
  }) {
    return SpeakerVerificationTelemetry(
      verificationCount: verificationCount ?? this.verificationCount,
      successfulMatches: successfulMatches ?? this.successfulMatches,
      failedMatches: failedMatches ?? this.failedMatches,
      averageLatencyMs: averageLatencyMs ?? this.averageLatencyMs,
      averageConfidence: averageConfidence ?? this.averageConfidence,
      averageSimilarity: averageSimilarity ?? this.averageSimilarity,
      falseRejectCount: falseRejectCount ?? this.falseRejectCount,
      falseAcceptCount: falseAcceptCount ?? this.falseAcceptCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'verificationCount': verificationCount,
        'successfulMatches': successfulMatches,
        'failedMatches': failedMatches,
        'averageLatencyMs': averageLatencyMs,
        'averageConfidence': averageConfidence,
        'averageSimilarity': averageSimilarity,
        'falseRejectCount': falseRejectCount,
        'falseAcceptCount': falseAcceptCount,
      };
}
