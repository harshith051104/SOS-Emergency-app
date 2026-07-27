/// health_collector.dart
///
/// Bounded timeout collector stub for wearable / health metrics.

library;

import 'dart:async';
import '../../domain/entities/sensor_health.dart';
import '../../domain/entities/telemetry_snapshot.dart';
import 'base_collector.dart';

class HealthCollector extends BaseTelemetryCollector<HealthTelemetry> {
  const HealthCollector();

  @override
  SensorType get sensorType => SensorType.health;

  @override
  Duration get defaultTimeoutBudget => const Duration(milliseconds: 500);

  @override
  Future<HealthTelemetry> collect({Duration? timeoutBudget}) async {
    // Standard default return when no smartwatch is connected
    return const HealthTelemetry(
      
    );
  }
}
