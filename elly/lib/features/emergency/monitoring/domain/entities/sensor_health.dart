/// sensor_health.dart
///
/// Domain entity representing per-sensor health lifecycle states.

library;

import 'package:equatable/equatable.dart';

enum SensorType {
  location,
  device,
  connectivity,
  application,
  motion,
  health,
}

enum SensorHealthStatus {
  healthy,
  degraded,
  unavailable,
  recovered,
}

class SensorHealth extends Equatable {
  const SensorHealth({
    required this.sensorType,
    required this.status,
    required this.lastChecked,
    this.consecutiveFailures = 0,
    this.failureReason,
  });

  final SensorType sensorType;
  final SensorHealthStatus status;
  final DateTime lastChecked;
  final int consecutiveFailures;
  final String? failureReason;

  bool get isOperational =>
      status == SensorHealthStatus.healthy ||
      status == SensorHealthStatus.degraded ||
      status == SensorHealthStatus.recovered;

  SensorHealth copyWith({
    SensorType? sensorType,
    SensorHealthStatus? status,
    DateTime? lastChecked,
    int? consecutiveFailures,
    String? failureReason,
  }) {
    return SensorHealth(
      sensorType: sensorType ?? this.sensorType,
      status: status ?? this.status,
      lastChecked: lastChecked ?? this.lastChecked,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  @override
  List<Object?> get props => [
        sensorType,
        status,
        lastChecked,
        consecutiveFailures,
        failureReason,
      ];
}
