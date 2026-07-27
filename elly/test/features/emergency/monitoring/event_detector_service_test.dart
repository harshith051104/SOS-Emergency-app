/// event_detector_service_test.dart
///
/// Unit tests for EventDetectorService comparing snapshots and tagging reason codes.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/telemetry_snapshot.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/telemetry_confidence.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/emergency_severity.dart';
import 'package:elly/features/emergency/monitoring/data/services/event_detector_service.dart';

void main() {
  group('EventDetectorService', () {
    final service = EventDetectorService();

    TelemetrySnapshot createSnapshot({
      bool isCharging = false,
      int battery = 80,
      bool internet = true,
      bool airplane = false,
      String motion = 'stationary',
    }) {
      return TelemetrySnapshot(
        utcTime: DateTime.now().toUtc(),
        localTime: DateTime.now(),
        monotonicElapsedMs: 1000,
        location: LocationTelemetry(
          latitude: 17.45,
          longitude: 78.38,
          accuracy: '5m',
          address: 'Test',
          timestamp: DateTime.now(),
          isGpsEnabled: true,
        ),
        device: DeviceTelemetry(
          batteryPercent: battery,
          isCharging: isCharging,
          isBatterySaverEnabled: false,
          isScreenLocked: false,
          deviceName: 'Phone',
          osVersion: '14',
          platform: 'Android',
          timeZone: 'UTC',
          locale: 'en',
        ),
        connectivity: ConnectivityTelemetry(
          isInternetAvailable: internet,
          connectionType: internet ? 'wifi' : 'none',
          isWifiEnabled: internet,
          isMobileDataEnabled: false,
          isBluetoothEnabled: true,
          isAirplaneModeEnabled: airplane,
        ),
        application: ApplicationTelemetry(
          isForeground: true,
          lastUserInteraction: DateTime.now(),
          sessionDuration: const Duration(minutes: 1),
          appVersion: '1.0.0',
        ),
        motion: MotionTelemetry(motionState: motion),
        health: const HealthTelemetry(),
        confidence: TelemetryConfidence.perfect(),
        severity: EmergencySeverity.defaultNormal(),
        sensorHealthMap: const {},
      );
    }

    test('should return initial_snapshot reason code on first cycle', () {
      final snap = createSnapshot();
      final result = service.detectStateChanges(
        current: snap,
        monotonicMs: 1000,
      );

      expect(result.reasonCode, equals('initial_snapshot'));
      expect(result.detectedEvents.first.eventType, equals('engine_started'));
    });

    test('should detect internet loss and return event_internet_lost reason code', () {
      final prev = createSnapshot();
      final curr = createSnapshot(internet: false);

      final result = service.detectStateChanges(
        current: curr,
        previous: prev,
        monotonicMs: 2000,
      );

      expect(result.reasonCode, equals('event_internet_lost'));
      expect(result.detectedEvents.any((e) => e.eventType == 'connectivity_changed'), isTrue);
    });

    test('should detect charging start and return event_charging_started reason code', () {
      final prev = createSnapshot();
      final curr = createSnapshot(isCharging: true);

      final result = service.detectStateChanges(
        current: curr,
        previous: prev,
        monotonicMs: 2000,
      );

      expect(result.reasonCode, equals('event_charging_started'));
    });
  });
}
