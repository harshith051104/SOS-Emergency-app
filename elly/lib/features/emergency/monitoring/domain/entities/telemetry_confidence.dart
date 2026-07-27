/// telemetry_confidence.dart
///
/// Domain entity rating the quality and trustworthiness of collected telemetry.

library;

import 'package:equatable/equatable.dart';

class TelemetryConfidence extends Equatable {
  const TelemetryConfidence({
    required this.locationConfidence,
    required this.networkConfidence,
    required this.motionConfidence,
    required this.batteryConfidence,
    required this.healthConfidence,
    required this.overallConfidence,
  });

  /// Location trustworthiness rating (0–100%).
  final int locationConfidence;

  /// Network/connectivity trustworthiness rating (0–100%).
  final int networkConfidence;

  /// Motion detection confidence (0–100%).
  final int motionConfidence;

  /// Battery sensor confidence (0–100%).
  final int batteryConfidence;

  /// Wearable/Health telemetry confidence (0–100%).
  final int healthConfidence;

  /// Aggregated confidence score across all telemetry (0–100%).
  final int overallConfidence;

  factory TelemetryConfidence.perfect() {
    return const TelemetryConfidence(
      locationConfidence: 100,
      networkConfidence: 100,
      motionConfidence: 100,
      batteryConfidence: 100,
      healthConfidence: 100,
      overallConfidence: 100,
    );
  }

  factory TelemetryConfidence.unknown() {
    return const TelemetryConfidence(
      locationConfidence: 0,
      networkConfidence: 0,
      motionConfidence: 0,
      batteryConfidence: 0,
      healthConfidence: 0,
      overallConfidence: 0,
    );
  }

  @override
  List<Object?> get props => [
        locationConfidence,
        networkConfidence,
        motionConfidence,
        batteryConfidence,
        healthConfidence,
        overallConfidence,
      ];
}
