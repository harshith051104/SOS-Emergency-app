/// sensor_health_monitor.dart
///
/// Service tracking sensor health states, consecutive failures, and recovery.

library;

import '../../domain/entities/sensor_health.dart';

class SensorHealthMonitor {
  SensorHealthMonitor();

  final Map<SensorType, SensorHealth> _sensorMap = {};

  Map<SensorType, SensorHealth> get currentHealthMap =>
      Map.unmodifiable(_sensorMap);

  /// Records a successful execution for a sensor.
  SensorHealth recordSuccess(SensorType type) {
    final prev = _sensorMap[type];
    final wasDegradedOrUnavailable = prev != null &&
        (prev.status == SensorHealthStatus.degraded ||
            prev.status == SensorHealthStatus.unavailable);

    final status = wasDegradedOrUnavailable
        ? SensorHealthStatus.recovered
        : SensorHealthStatus.healthy;

    final health = SensorHealth(
      sensorType: type,
      status: status,
      lastChecked: DateTime.now(),
    );

    _sensorMap[type] = health;
    return health;
  }

  /// Records a failure or timeout for a sensor.
  SensorHealth recordFailure(SensorType type, String reason) {
    final prev = _sensorMap[type];
    final failures = (prev?.consecutiveFailures ?? 0) + 1;

    final status = failures >= 3
        ? SensorHealthStatus.unavailable
        : SensorHealthStatus.degraded;

    final health = SensorHealth(
      sensorType: type,
      status: status,
      lastChecked: DateTime.now(),
      consecutiveFailures: failures,
      failureReason: reason,
    );

    _sensorMap[type] = health;
    return health;
  }

  SensorHealth getHealth(SensorType type) {
    return _sensorMap[type] ??
        SensorHealth(
          sensorType: type,
          status: SensorHealthStatus.healthy,
          lastChecked: DateTime.now(),
        );
  }
}
