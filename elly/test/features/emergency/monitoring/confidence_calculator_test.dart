/// confidence_calculator_test.dart
///
/// Unit tests for Telemetry Confidence scoring algorithm.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/telemetry_snapshot.dart';
import 'package:elly/features/emergency/monitoring/data/services/confidence_calculator.dart';

void main() {
  group('ConfidenceCalculator', () {
    const calculator = ConfidenceCalculator();

    test('should return 100% confidence for ideal sensors and valid location', () {
      final loc = LocationTelemetry(
        latitude: 17.4532,
        longitude: 78.3819,
        accuracy: '4.0m',
        address: 'Hyderabad, India',
        timestamp: DateTime.now(),
        isGpsEnabled: true,
      );

      const dev = DeviceTelemetry(
        batteryPercent: 85,
        isCharging: false,
        isBatterySaverEnabled: false,
        isScreenLocked: false,
        deviceName: 'Test Phone',
        osVersion: 'Android 14',
        platform: 'Android',
        timeZone: 'IST',
        locale: 'en_IN',
      );

      const conn = ConnectivityTelemetry(
        isInternetAvailable: true,
        connectionType: 'wifi',
        isWifiEnabled: true,
        isMobileDataEnabled: true,
        isBluetoothEnabled: true,
        isAirplaneModeEnabled: false,
      );

      const mot = MotionTelemetry(motionState: 'walking');
      const hlth = HealthTelemetry();

      final confidence = calculator.calculate(
        location: loc,
        device: dev,
        connectivity: conn,
        motion: mot,
        health: hlth,
        sensorHealthMap: const {},
      );

      expect(confidence.locationConfidence, equals(100));
      expect(confidence.networkConfidence, equals(100));
      expect(confidence.motionConfidence, equals(100));
      expect(confidence.batteryConfidence, equals(100));
      expect(confidence.overallConfidence, greaterThanOrEqualTo(90));
    });

    test('should penalize confidence when mock location is detected', () {
      final loc = LocationTelemetry(
        latitude: 17.4532,
        longitude: 78.3819,
        accuracy: '4.0m',
        address: 'Mock Location',
        timestamp: DateTime.now(),
        isGpsEnabled: true,
        isMockLocation: true,
      );

      const dev = DeviceTelemetry(
        batteryPercent: 50,
        isCharging: false,
        isBatterySaverEnabled: false,
        isScreenLocked: false,
        deviceName: 'Test Phone',
        osVersion: 'Android 14',
        platform: 'Android',
        timeZone: 'IST',
        locale: 'en_IN',
      );

      const conn = ConnectivityTelemetry(
        isInternetAvailable: false,
        connectionType: 'none',
        isWifiEnabled: false,
        isMobileDataEnabled: false,
        isBluetoothEnabled: false,
        isAirplaneModeEnabled: false,
      );

      const mot = MotionTelemetry(motionState: 'unknown', confidenceScore: 50);
      const hlth = HealthTelemetry();

      final confidence = calculator.calculate(
        location: loc,
        device: dev,
        connectivity: conn,
        motion: mot,
        health: hlth,
        sensorHealthMap: const {},
      );

      expect(confidence.locationConfidence, lessThan(100));
      expect(confidence.networkConfidence, equals(30));
    });
  });
}
