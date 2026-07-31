/// intent_telemetry.dart
///
/// Telemetry metrics model capturing intent classification statistics and latency profiling.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent.dart';

@immutable
class IntentTelemetry {
  const IntentTelemetry({
    this.classificationCounts = const {
      EmergencyIntent.emergency: 0,
      EmergencyIntent.possibleEmergency: 0,
      EmergencyIntent.nonEmergency: 0,
      EmergencyIntent.unknown: 0,
    },
    this.languageDistribution = const {},
    this.averageLatencyMs = 0,
    this.averageConfidence = 0.0,
    this.averageTranscriptLength = 0,
    this.unknownClassificationCount = 0,
    this.timeoutCount = 0,
    this.failureCount = 0,
  });

  final Map<EmergencyIntent, int> classificationCounts;
  final Map<String, int> languageDistribution;
  final int averageLatencyMs;
  final double averageConfidence;
  final int averageTranscriptLength;
  final int unknownClassificationCount;
  final int timeoutCount;
  final int failureCount;

  IntentTelemetry copyWith({
    Map<EmergencyIntent, int>? classificationCounts,
    Map<String, int>? languageDistribution,
    int? averageLatencyMs,
    double? averageConfidence,
    int? averageTranscriptLength,
    int? unknownClassificationCount,
    int? timeoutCount,
    int? failureCount,
  }) {
    return IntentTelemetry(
      classificationCounts: classificationCounts ?? this.classificationCounts,
      languageDistribution: languageDistribution ?? this.languageDistribution,
      averageLatencyMs: averageLatencyMs ?? this.averageLatencyMs,
      averageConfidence: averageConfidence ?? this.averageConfidence,
      averageTranscriptLength: averageTranscriptLength ?? this.averageTranscriptLength,
      unknownClassificationCount: unknownClassificationCount ?? this.unknownClassificationCount,
      timeoutCount: timeoutCount ?? this.timeoutCount,
      failureCount: failureCount ?? this.failureCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'classificationCounts': classificationCounts.map((k, v) => MapEntry(k.name, v)),
        'languageDistribution': languageDistribution,
        'averageLatencyMs': averageLatencyMs,
        'averageConfidence': averageConfidence,
        'averageTranscriptLength': averageTranscriptLength,
        'unknownClassificationCount': unknownClassificationCount,
        'timeoutCount': timeoutCount,
        'failureCount': failureCount,
      };
}
