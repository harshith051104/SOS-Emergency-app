/// base_collector.dart
///
/// Base interface for telemetry collectors with strict timeout budget enforcement.

library;

import '../../domain/entities/sensor_health.dart';

abstract class BaseTelemetryCollector<T> {
  const BaseTelemetryCollector();

  SensorType get sensorType;
  Duration get defaultTimeoutBudget;

  /// Gathers telemetry metrics within the specified timeout budget.
  Future<T> collect({Duration? timeoutBudget});
}
