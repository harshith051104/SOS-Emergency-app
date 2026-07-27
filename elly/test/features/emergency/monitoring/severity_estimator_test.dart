/// severity_estimator_test.dart
///
/// Unit tests for Emergency Severity Estimator rules engine.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/emergency_severity.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/telemetry_snapshot.dart';
import 'package:elly/features/emergency/monitoring/data/services/severity_estimator.dart';

void main() {
  group('SeverityEstimator', () {
    const estimator = SeverityEstimator();

    test('should calculate CRITICAL severity when battery level <= 10%, internet lost, and airplane mode is enabled', () {
      final loc = LocationTelemetry(
        accuracy: 'No signal',
        address: 'No GPS',
        timestamp: DateTime.now(),
        isGpsEnabled: false,
      );

      const dev = DeviceTelemetry(
        batteryPercent: 8,
        isCharging: false,
        isBatterySaverEnabled: true,
        isScreenLocked: false,
        deviceName: 'Test Device',
        osVersion: 'Android 14',
        platform: 'Android',
        timeZone: 'UTC',
        locale: 'en',
      );

      const conn = ConnectivityTelemetry(
        isInternetAvailable: false,
        connectionType: 'none',
        isWifiEnabled: false,
        isMobileDataEnabled: false,
        isBluetoothEnabled: false,
        isAirplaneModeEnabled: true,
      );

      const mot = MotionTelemetry(motionState: 'stationary');

      final severity = estimator.estimate(
        location: loc,
        device: dev,
        connectivity: conn,
        motion: mot,
      );

      expect(severity.level, equals(EmergencySeverityLevel.critical));
      expect(severity.score, greaterThanOrEqualTo(80));
      expect(severity.contributingFactors, contains(contains('Critical Battery')));
      expect(severity.contributingFactors, contains(contains('Airplane Mode Active')));
    });

    test('should calculate MEDIUM severity for standard SOS with normal battery and internet available', () {
      final loc = LocationTelemetry(
        latitude: 17.45,
        longitude: 78.38,
        accuracy: '5m',
        address: 'Test Address',
        timestamp: DateTime.now(),
        isGpsEnabled: true,
      );

      const dev = DeviceTelemetry(
        batteryPercent: 90,
        isCharging: false,
        isBatterySaverEnabled: false,
        isScreenLocked: false,
        deviceName: 'Test Device',
        osVersion: 'Android 14',
        platform: 'Android',
        timeZone: 'UTC',
        locale: 'en',
      );

      const conn = ConnectivityTelemetry(
        isInternetAvailable: true,
        connectionType: 'cellular',
        isWifiEnabled: false,
        isMobileDataEnabled: true,
        isBluetoothEnabled: true,
        isAirplaneModeEnabled: false,
      );

      const mot = MotionTelemetry(motionState: 'walking');

      final severity = estimator.estimate(
        location: loc,
        device: dev,
        connectivity: conn,
        motion: mot,
      );

      expect(severity.level, equals(EmergencySeverityLevel.medium));
      expect(severity.score, lessThan(60));
    });
  });
}
