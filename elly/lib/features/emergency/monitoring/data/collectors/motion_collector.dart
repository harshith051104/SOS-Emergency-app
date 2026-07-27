/// motion_collector.dart
///
/// Bounded timeout collector for user physical activity & motion.

library;

import 'dart:async';
import '../../domain/entities/sensor_health.dart';
import '../../domain/entities/telemetry_snapshot.dart';
import 'base_collector.dart';

class MotionCollector extends BaseTelemetryCollector<MotionTelemetry> {
  const MotionCollector({
    this.currentSpeedMps,
  });

  final double? currentSpeedMps;

  @override
  SensorType get sensorType => SensorType.motion;

  @override
  Duration get defaultTimeoutBudget => const Duration(milliseconds: 500);

  @override
  Future<MotionTelemetry> collect({Duration? timeoutBudget}) async {
    String motionState = 'stationary';

    if (currentSpeedMps != null) {
      final speed = currentSpeedMps!;
      if (speed > 7.0) {
        motionState = 'vehicle';
      } else if (speed > 2.5) {
        motionState = 'running';
      } else if (speed > 0.5) {
        motionState = 'walking';
      } else {
        motionState = 'stationary';
      }
    }

    return MotionTelemetry(
      motionState: motionState,
      confidenceScore: 85,
    );
  }
}
