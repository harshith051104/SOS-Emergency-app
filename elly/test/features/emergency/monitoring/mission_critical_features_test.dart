/// mission_critical_features_test.dart
///
/// Unit tests for Battery Budget Manager, Monitoring Watchdog, Packet Checksum Integrity Verification, and Session Integrity Report.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/sensor_health.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/packet_record.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/telemetry_snapshot.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/telemetry_confidence.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/emergency_severity.dart';
import 'package:elly/features/emergency/monitoring/data/services/battery_budget_manager.dart';
import 'package:elly/features/emergency/monitoring/data/services/monitoring_watchdog.dart';
import 'package:elly/features/emergency/monitoring/data/services/monitoring_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mission-Critical Monitoring Capabilities', () {
    // 1. Battery Budget Manager Tests
    test('BatteryBudgetManager should shed optional/important sensors during low battery states', () {
      const manager = BatteryBudgetManager();

      // Normal battery state (>20%)
      final normalPolicy = manager.evaluatePolicy(batteryPercent: 80, isCharging: false);
      expect(normalPolicy.shouldCollectMotion, isTrue);
      expect(normalPolicy.shouldCollectHealth, isTrue);

      // Low battery state (15%) -> Shed optional (health)
      final lowPolicy = manager.evaluatePolicy(batteryPercent: 15, isCharging: false);
      expect(lowPolicy.shouldCollectMotion, isTrue);
      expect(lowPolicy.shouldCollectHealth, isFalse);

      // Critical battery state (8%) -> Shed optional and important (health & motion)
      final criticalPolicy = manager.evaluatePolicy(batteryPercent: 8, isCharging: false);
      expect(criticalPolicy.shouldCollectMotion, isFalse);
      expect(criticalPolicy.shouldCollectHealth, isFalse);

      // Critical sensors (GPS, Battery, Connectivity) are ALWAYS allowed regardless of battery level
      expect(manager.isSensorAllowed(sensorType: SensorType.location, batteryPercent: 5, isCharging: false), isTrue);
      expect(manager.isSensorAllowed(sensorType: SensorType.device, batteryPercent: 5, isCharging: false), isTrue);
      expect(manager.isSensorAllowed(sensorType: SensorType.connectivity, batteryPercent: 5, isCharging: false), isTrue);
    });

    // 2. Monitoring Watchdog Tests
    test('MonitoringWatchdog should detect execution stall and fire onStallDetected callback', () async {
      bool stallFired = false;

      final watchdog = MonitoringWatchdog(
        maxStallMultiplier: 1.2,
        onStallDetected: () async {
          stallFired = true;
        },
      );

      watchdog.startWatchdog(const Duration(milliseconds: 100));

      // Wait longer than 1.2x expected interval (120ms) without pinging heartbeat
      await Future.delayed(const Duration(milliseconds: 180));

      expect(stallFired, isTrue);
      watchdog.stopWatchdog();
    });

    // 3. Packet Integrity Verification Tests
    test('MonitoringStorageService should detect corrupted checksums and quarantine invalid packets', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = MonitoringStorageService();
      final now = DateTime.now();

      final validPacket = PacketRecord(
        packetNumber: 1,
        reasonCode: 'periodic_cycle',
        sessionId: 'session_corrupt_test',
        utcTime: now.toUtc(),
        localTime: now,
        monotonicElapsedMs: 100,
        sessionDuration: const Duration(seconds: 10),
        checksum: '', // Placeholder
        telemetry: TelemetrySnapshot(
          utcTime: now.toUtc(),
          localTime: now,
          monotonicElapsedMs: 100,
          location: LocationTelemetry(
            latitude: 17.45,
            longitude: 78.38,
            accuracy: '5m',
            address: 'Test',
            timestamp: now,
            isGpsEnabled: true,
          ),
          device: const DeviceTelemetry(
            batteryPercent: 80,
            isCharging: false,
            isBatterySaverEnabled: false,
            isScreenLocked: false,
            deviceName: 'Phone',
            osVersion: '14',
            platform: 'Android',
            timeZone: 'UTC',
            locale: 'en',
          ),
          connectivity: const ConnectivityTelemetry(
            isInternetAvailable: true,
            connectionType: 'wifi',
            isWifiEnabled: true,
            isMobileDataEnabled: false,
            isBluetoothEnabled: true,
            isAirplaneModeEnabled: false,
          ),
          application: ApplicationTelemetry(
            isForeground: true,
            lastUserInteraction: now,
            sessionDuration: const Duration(seconds: 10),
            appVersion: '1.0.0',
          ),
          motion: const MotionTelemetry(motionState: 'stationary'),
          health: const HealthTelemetry(),
          confidence: TelemetryConfidence.perfect(),
          severity: EmergencySeverity.defaultNormal(),
          sensorHealthMap: const {},
        ),
      );

      final payloadForHash = '${validPacket.sessionId}|${validPacket.packetNumber}|${validPacket.reasonCode}|${validPacket.utcTime.toIso8601String()}|${validPacket.telemetry.location.latitude},${validPacket.telemetry.location.longitude}|${validPacket.telemetry.device.batteryPercent}|${validPacket.telemetry.confidence.overallConfidence}|${validPacket.telemetry.severity.score}';
      final validChecksum = storage.calculateFnv1aChecksum(payloadForHash);

      final packetWithValidHash = PacketRecord(
        schemaVersion: validPacket.schemaVersion,
        packetNumber: validPacket.packetNumber,
        reasonCode: validPacket.reasonCode,
        sessionId: validPacket.sessionId,
        utcTime: validPacket.utcTime,
        localTime: validPacket.localTime,
        monotonicElapsedMs: validPacket.monotonicElapsedMs,
        sessionDuration: validPacket.sessionDuration,
        checksum: validChecksum,
        telemetry: validPacket.telemetry,
      );

      final corruptedPacket = PacketRecord(
        packetNumber: 2,
        reasonCode: 'periodic_cycle',
        sessionId: 'session_corrupt_test',
        utcTime: now.toUtc(),
        localTime: now,
        monotonicElapsedMs: 200,
        sessionDuration: const Duration(seconds: 20),
        checksum: 'BAD_HASH_CORRUPT', // Invalid tampered hash
        telemetry: validPacket.telemetry,
      );

      await storage.savePacket(packetWithValidHash);
      await storage.savePacket(corruptedPacket);

      // Verify corrupted packet is quarantined when skipCorrupted: true
      final validOnly = await storage.getPackets('session_corrupt_test');
      expect(validOnly.length, equals(1));
      expect(validOnly.first.packetNumber, equals(1));

      // Session Integrity Report generation
      final report = await storage.generateSessionIntegrityReport('session_corrupt_test');
      expect(report.packetsStored, equals(1));
      expect(report.corruptedPacketsDetected, equals(1));
    });
  });
}
