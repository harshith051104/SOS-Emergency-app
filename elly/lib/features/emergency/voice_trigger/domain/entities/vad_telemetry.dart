/// vad_telemetry.dart
///
/// Telemetry metrics for VAD engine uptime, detection counts, CPU, and battery usage.

library;

import 'package:flutter/foundation.dart';

@immutable
class VadTelemetry {
  const VadTelemetry({
    this.uptimeSeconds = 0,
    this.detectionCount = 0,
    this.speechDurationMs = 0,
    this.estimatedCpuPercent = 0.8,
    this.estimatedRamMb = 14.5,
    this.batteryLevel = 100,
    this.lastEventTimestamp,
  });

  final int uptimeSeconds;
  final int detectionCount;
  final int speechDurationMs;
  final double estimatedCpuPercent;
  final double estimatedRamMb;
  final int batteryLevel;
  final DateTime? lastEventTimestamp;

  VadTelemetry copyWith({
    int? uptimeSeconds,
    int? detectionCount,
    int? speechDurationMs,
    double? estimatedCpuPercent,
    double? estimatedRamMb,
    int? batteryLevel,
    DateTime? lastEventTimestamp,
  }) {
    return VadTelemetry(
      uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
      detectionCount: detectionCount ?? this.detectionCount,
      speechDurationMs: speechDurationMs ?? this.speechDurationMs,
      estimatedCpuPercent: estimatedCpuPercent ?? this.estimatedCpuPercent,
      estimatedRamMb: estimatedRamMb ?? this.estimatedRamMb,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastEventTimestamp: lastEventTimestamp ?? this.lastEventTimestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'uptimeSeconds': uptimeSeconds,
        'detectionCount': detectionCount,
        'speechDurationMs': speechDurationMs,
        'estimatedCpuPercent': estimatedCpuPercent,
        'estimatedRamMb': estimatedRamMb,
        'batteryLevel': batteryLevel,
        'lastEventTimestamp': lastEventTimestamp?.toIso8601String(),
      };
}
