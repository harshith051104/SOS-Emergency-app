/// speech_telemetry.dart
///
/// Telemetry model capturing performance, latency, and operational metrics for STT inference.

library;

import 'package:flutter/foundation.dart';

@immutable
class SpeechTelemetry {
  const SpeechTelemetry({
    this.recognitionsCompleted = 0,
    this.recognitionsFailed = 0,
    this.averageInferenceTimeMs = 0,
    this.averageUtteranceDurationMs = 0,
    this.averageConfidence = 0.0,
    this.cancellationCount = 0,
    this.modelLoadTimeMs = 0,
    this.timeoutCount = 0,
    this.averageQueueWaitTimeMs = 0,
  });

  final int recognitionsCompleted;
  final int recognitionsFailed;
  final int averageInferenceTimeMs;
  final int averageUtteranceDurationMs;
  final double averageConfidence;
  final int cancellationCount;
  final int modelLoadTimeMs;
  final int timeoutCount;
  final int averageQueueWaitTimeMs;

  SpeechTelemetry copyWith({
    int? recognitionsCompleted,
    int? recognitionsFailed,
    int? averageInferenceTimeMs,
    int? averageUtteranceDurationMs,
    double? averageConfidence,
    int? cancellationCount,
    int? modelLoadTimeMs,
    int? timeoutCount,
    int? averageQueueWaitTimeMs,
  }) {
    return SpeechTelemetry(
      recognitionsCompleted: recognitionsCompleted ?? this.recognitionsCompleted,
      recognitionsFailed: recognitionsFailed ?? this.recognitionsFailed,
      averageInferenceTimeMs: averageInferenceTimeMs ?? this.averageInferenceTimeMs,
      averageUtteranceDurationMs: averageUtteranceDurationMs ?? this.averageUtteranceDurationMs,
      averageConfidence: averageConfidence ?? this.averageConfidence,
      cancellationCount: cancellationCount ?? this.cancellationCount,
      modelLoadTimeMs: modelLoadTimeMs ?? this.modelLoadTimeMs,
      timeoutCount: timeoutCount ?? this.timeoutCount,
      averageQueueWaitTimeMs: averageQueueWaitTimeMs ?? this.averageQueueWaitTimeMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'recognitionsCompleted': recognitionsCompleted,
        'recognitionsFailed': recognitionsFailed,
        'averageInferenceTimeMs': averageInferenceTimeMs,
        'averageUtteranceDurationMs': averageUtteranceDurationMs,
        'averageConfidence': averageConfidence,
        'cancellationCount': cancellationCount,
        'modelLoadTimeMs': modelLoadTimeMs,
        'timeoutCount': timeoutCount,
        'averageQueueWaitTimeMs': averageQueueWaitTimeMs,
      };
}
