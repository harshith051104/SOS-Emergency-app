/// monitoring_storage_service_test.dart
///
/// Unit & integration tests for MonitoringStorageService persistence and FNV-1a checksum hash calculation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/packet_record.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/telemetry_snapshot.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/telemetry_confidence.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/emergency_severity.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/timeline_entry.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/session_metadata.dart';
import 'package:elly/features/emergency/monitoring/data/services/monitoring_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonitoringStorageService', () {
    late MonitoringStorageService storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = MonitoringStorageService();
    });

    test('should calculate valid FNV-1a checksum string', () {
      final checksum = storage.calculateFnv1aChecksum('TEST_PAYLOAD_STRING');
      expect(checksum.length, equals(8));
      expect(checksum, matches(RegExp(r'^[0-9A-F]{8}$')));
    });

    test('should save and load immutable packet records', () async {
      final now = DateTime.now();
      final packet = PacketRecord(
        packetNumber: 1,
        reasonCode: 'periodic_cycle',
        sessionId: 'session_abc_123',
        utcTime: now.toUtc(),
        localTime: now,
        monotonicElapsedMs: 500,
        sessionDuration: const Duration(seconds: 10),
        checksum: 'A1B2C3D4E5F67890',
        telemetry: TelemetrySnapshot(
          utcTime: now.toUtc(),
          localTime: now,
          monotonicElapsedMs: 500,
          location: LocationTelemetry(
            latitude: 17.4532,
            longitude: 78.3819,
            accuracy: '4.0m',
            address: 'Hyderabad',
            timestamp: now,
            isGpsEnabled: true,
          ),
          device: const DeviceTelemetry(
            batteryPercent: 85,
            isCharging: false,
            isBatterySaverEnabled: false,
            isScreenLocked: false,
            deviceName: 'Test Phone',
            osVersion: '14',
            platform: 'Android',
            timeZone: 'IST',
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

      await storage.savePacket(packet);
      final loaded = await storage.getPackets('session_abc_123');

      expect(loaded.length, equals(1));
      expect(loaded.first.packetNumber, equals(1));
      expect(loaded.first.sessionId, equals('session_abc_123'));
      expect(loaded.first.checksum, equals('A1B2C3D4E5F67890'));
      expect(loaded.first.telemetry.location.latitude, equals(17.4532));
    });

    test('should save, load, and clear active session metadata', () async {
      final meta = SessionMetadata(
        sessionId: 'session_recovery_test',
        startedAt: DateTime.now(),
        isSessionActive: true,
        triggerType: 'manual_sos',
        lastPacketNumber: 42,
        lastUpdatedUtc: DateTime.now().toUtc(),
      );

      await storage.saveSessionMetadata(meta);
      final loaded = await storage.getActiveSessionMetadata();

      expect(loaded, isNotNull);
      expect(loaded!.sessionId, equals('session_recovery_test'));
      expect(loaded.lastPacketNumber, equals(42));

      await storage.clearActiveSessionMetadata();
      final cleared = await storage.getActiveSessionMetadata();
      expect(cleared, isNull);
    });

    test('should save and load append-only timeline logs', () async {
      final now = DateTime.now();
      final entry = TimelineEntry(
        id: 'evt_1',
        utcTime: now.toUtc(),
        localTime: now,
        monotonicElapsedMs: 100,
        title: 'SOS Triggered',
        description: 'User initiated SOS button press.',
        eventType: 'manual_sos',
        category: 'user',
      );

      await storage.saveTimelineEntry('session_timeline_test', entry);
      final timeline = await storage.getTimeline('session_timeline_test');

      expect(timeline.length, equals(1));
      expect(timeline.first.title, equals('SOS Triggered'));
    });
  });
}
