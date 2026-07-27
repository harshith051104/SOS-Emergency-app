/// telemetry_validator.dart
///
/// Pure domain validator evaluating telemetry points, computing confidence scores,
/// and assigning TelemetryQuality levels (excellent, good, poor, rejected).

library;

import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_point.dart';

class TelemetryValidationResult {
  const TelemetryValidationResult._(this.isValid, this.reason, this.evaluatedPoint);

  factory TelemetryValidationResult.valid(TelemetryPoint point) =>
      TelemetryValidationResult._(true, null, point);

  factory TelemetryValidationResult.invalid(String reason, TelemetryPoint point) =>
      TelemetryValidationResult._(false, reason, point.copyWith(quality: TelemetryQuality.rejected, confidenceScore: 0.0));

  final bool isValid;
  final String? reason;
  final TelemetryPoint evaluatedPoint;
}

class TelemetryValidator {
  static const double maxAcceptableAccuracyMeters = 100.0;
  static const double maxPossibleSpeedMs = 83.33; // 300 km/h

  /// Validates point and calculates confidence score & quality level.
  static TelemetryValidationResult validatePoint(TelemetryPoint rawPoint, {TelemetryPoint? previousPoint}) {
    if (rawPoint.latitude < -90.0 || rawPoint.latitude > 90.0) {
      return TelemetryValidationResult.invalid(
        'Latitude out of range [-90, 90]: ${rawPoint.latitude}',
        rawPoint,
      );
    }

    if (rawPoint.longitude < -180.0 || rawPoint.longitude > 180.0) {
      return TelemetryValidationResult.invalid(
        'Longitude out of range [-180, 180]: ${rawPoint.longitude}',
        rawPoint,
      );
    }

    if (rawPoint.accuracy > maxAcceptableAccuracyMeters) {
      return TelemetryValidationResult.invalid(
        'Accuracy threshold exceeded (${rawPoint.accuracy}m > 100m)',
        rawPoint,
      );
    }

    if (rawPoint.speed > maxPossibleSpeedMs) {
      return TelemetryValidationResult.invalid(
        'Impossible speed detected: ${(rawPoint.speed * 3.6).toStringAsFixed(1)} km/h',
        rawPoint,
      );
    }

    if (rawPoint.timestamp.isAfter(DateTime.now().add(const Duration(seconds: 10)))) {
      return TelemetryValidationResult.invalid(
        'Future timestamp detected: ${rawPoint.timestamp}',
        rawPoint,
      );
    }

    if (previousPoint != null) {
      if (previousPoint.latitude == rawPoint.latitude && previousPoint.longitude == rawPoint.longitude) {
        final diffMs = rawPoint.timestamp.difference(previousPoint.timestamp).inMilliseconds;
        if (diffMs < 500) {
          return TelemetryValidationResult.invalid('Duplicate location sample discarded.', rawPoint);
        }
      }
    }

    // Compute quality rating & confidence score based on accuracy meters
    final TelemetryQuality quality;
    final double confidence;

    if (rawPoint.accuracy <= 10.0) {
      quality = TelemetryQuality.excellent;
      confidence = 0.98;
    } else if (rawPoint.accuracy <= 25.0) {
      quality = TelemetryQuality.good;
      confidence = 0.85;
    } else {
      quality = TelemetryQuality.poor;
      confidence = 0.50;
    }

    final evaluatedPoint = rawPoint.copyWith(
      quality: quality,
      confidenceScore: confidence,
    );

    return TelemetryValidationResult.valid(evaluatedPoint);
  }
}
