/// telemetry_result.dart
///
/// Immutable domain model representing telemetry operation outcome.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_point.dart';

@immutable
class TelemetryResult {
  const TelemetryResult({
    required this.success,
    this.latestPoint,
    this.reason,
  });

  final bool success;
  final TelemetryPoint? latestPoint;
  final String? reason;

  factory TelemetryResult.success(TelemetryPoint point) => TelemetryResult(
        success: true,
        latestPoint: point,
      );

  factory TelemetryResult.failure(String reason) => TelemetryResult(
        success: false,
        reason: reason,
      );
}
