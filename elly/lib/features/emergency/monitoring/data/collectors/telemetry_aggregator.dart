/// telemetry_aggregator.dart
///
/// Orchestrates parallel sensor collection, updates sensor health, and compiles TelemetrySnapshot.

library;

import 'dart:async';
import '../../domain/entities/telemetry_snapshot.dart';
import '../../domain/entities/sensor_health.dart';
import '../services/sensor_health_monitor.dart';
import '../services/confidence_calculator.dart';
import '../services/severity_estimator.dart';
import 'location_collector.dart';
import 'device_collector.dart';
import 'connectivity_collector.dart';
import 'application_collector.dart';
import 'motion_collector.dart';
import 'health_collector.dart';

class TelemetryAggregator {
  TelemetryAggregator({
    LocationCollector? locationCollector,
    DeviceCollector? deviceCollector,
    ConnectivityCollector? connectivityCollector,
    ApplicationCollector? applicationCollector,
    MotionCollector? motionCollector,
    HealthCollector? healthCollector,
    SensorHealthMonitor? healthMonitor,
    ConfidenceCalculator? confidenceCalculator,
    SeverityEstimator? severityEstimator,
  })  : _locationCollector = locationCollector ?? const LocationCollector(),
        _deviceCollector = deviceCollector ?? DeviceCollector(),
        _connectivityCollector =
            connectivityCollector ?? ConnectivityCollector(),
        _applicationCollector = applicationCollector,
        _motionCollector = motionCollector ?? const MotionCollector(),
        _healthCollector = healthCollector ?? const HealthCollector(),
        _healthMonitor = healthMonitor ?? SensorHealthMonitor(),
        _confidenceCalculator =
            confidenceCalculator ?? const ConfidenceCalculator(),
        _severityEstimator = severityEstimator ?? const SeverityEstimator(),
        _startTimeMs = DateTime.now().millisecondsSinceEpoch;

  final LocationCollector _locationCollector;
  final DeviceCollector _deviceCollector;
  final ConnectivityCollector _connectivityCollector;
  final ApplicationCollector? _applicationCollector;
  final MotionCollector _motionCollector;
  final HealthCollector _healthCollector;

  final SensorHealthMonitor _healthMonitor;
  final ConfidenceCalculator _confidenceCalculator;
  final SeverityEstimator _severityEstimator;
  final int _startTimeMs;

  SensorHealthMonitor get healthMonitor => _healthMonitor;

  /// Aggregates all sensor metrics safely within per-collector timeout budgets.
  Future<TelemetrySnapshot> aggregate({
    required DateTime sessionStartedAt,
    Duration locationTimeout = const Duration(milliseconds: 2000),
    Duration deviceTimeout = const Duration(milliseconds: 100),
    Duration connectivityTimeout = const Duration(milliseconds: 200),
    Duration motionTimeout = const Duration(milliseconds: 500),
    Duration healthTimeout = const Duration(milliseconds: 500),
    bool enableHealth = false,
    bool enableMotion = true,
  }) async {
    final nowUtc = DateTime.now().toUtc();
    final nowLocal = DateTime.now();
    final monotonicMs = nowLocal.millisecondsSinceEpoch - _startTimeMs;

    final appCollector = _applicationCollector ??
        ApplicationCollector(sessionStartedAt: sessionStartedAt);

    // Run parallel collections with try-catch and timeout guards
    final locationFuture = _safeCollect<LocationTelemetry>(
      SensorType.location,
      () => _locationCollector.collect(timeoutBudget: locationTimeout),
      LocationTelemetry(
        accuracy: 'Error',
        address: 'Collector Exception',
        timestamp: nowLocal,
        isGpsEnabled: false,
      ),
    );

    final deviceFuture = _safeCollect<DeviceTelemetry>(
      SensorType.device,
      () => _deviceCollector.collect(timeoutBudget: deviceTimeout),
      const DeviceTelemetry(
        batteryPercent: 100,
        isCharging: false,
        isBatterySaverEnabled: false,
        isScreenLocked: false,
        deviceName: 'Generic Device',
        osVersion: 'Unknown OS',
        platform: 'Android',
        timeZone: 'UTC',
        locale: 'en',
      ),
    );

    final connectivityFuture = _safeCollect<ConnectivityTelemetry>(
      SensorType.connectivity,
      () => _connectivityCollector.collect(timeoutBudget: connectivityTimeout),
      const ConnectivityTelemetry(
        isInternetAvailable: false,
        connectionType: 'none',
        isWifiEnabled: false,
        isMobileDataEnabled: false,
        isBluetoothEnabled: false,
        isAirplaneModeEnabled: false,
      ),
    );

    final appFuture = _safeCollect<ApplicationTelemetry>(
      SensorType.application,
      () => appCollector.collect(timeoutBudget: const Duration(milliseconds: 100)),
      ApplicationTelemetry(
        isForeground: true,
        lastUserInteraction: nowLocal,
        sessionDuration: nowLocal.difference(sessionStartedAt),
        appVersion: '1.0.0',
      ),
    );

    final motionFuture = enableMotion
        ? _safeCollect<MotionTelemetry>(
            SensorType.motion,
            () => _motionCollector.collect(timeoutBudget: motionTimeout),
            const MotionTelemetry(motionState: 'unknown'),
          )
        : Future.value(const MotionTelemetry(motionState: 'disabled'));

    final healthFuture = enableHealth
        ? _safeCollect<HealthTelemetry>(
            SensorType.health,
            () => _healthCollector.collect(timeoutBudget: healthTimeout),
            const HealthTelemetry(),
          )
        : Future.value(const HealthTelemetry());

    final results = await Future.wait([
      locationFuture,
      deviceFuture,
      connectivityFuture,
      appFuture,
      motionFuture,
      healthFuture,
    ]);

    final location = results[0] as LocationTelemetry;
    final device = results[1] as DeviceTelemetry;
    final connectivity = results[2] as ConnectivityTelemetry;
    final application = results[3] as ApplicationTelemetry;
    final motion = results[4] as MotionTelemetry;
    final health = results[5] as HealthTelemetry;

    final confidence = _confidenceCalculator.calculate(
      location: location,
      device: device,
      connectivity: connectivity,
      motion: motion,
      health: health,
      sensorHealthMap: _healthMonitor.currentHealthMap,
    );

    final severity = _severityEstimator.estimate(
      location: location,
      device: device,
      connectivity: connectivity,
      motion: motion,
    );

    return TelemetrySnapshot(
      utcTime: nowUtc,
      localTime: nowLocal,
      monotonicElapsedMs: monotonicMs,
      location: location,
      device: device,
      connectivity: connectivity,
      application: application,
      motion: motion,
      health: health,
      confidence: confidence,
      severity: severity,
      sensorHealthMap: _healthMonitor.currentHealthMap,
    );
  }

  Future<T> _safeCollect<T>(
    SensorType sensorType,
    Future<T> Function() action,
    T fallback,
  ) async {
    try {
      final res = await action();
      _healthMonitor.recordSuccess(sensorType);
      return res;
    } catch (e) {
      _healthMonitor.recordFailure(sensorType, e.toString());
      return fallback;
    }
  }
}
