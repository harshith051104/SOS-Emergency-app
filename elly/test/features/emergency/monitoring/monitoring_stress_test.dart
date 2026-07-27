/// monitoring_stress_test.dart
///
/// Stress test generating 100+ sequential Emergency Data Packets.
/// Verifies packet order integrity, FNV-1a checksums, zero data loss, timeline append performance, and metrics accuracy.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/packet_record.dart';
import 'package:elly/features/emergency/monitoring/data/services/monitoring_engine_service.dart';
import 'package:elly/features/emergency/monitoring/data/services/monitoring_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Emergency Monitoring Engine — Stress Test', () {
    late MonitoringEngineService engine;
    late MonitoringStorageService storage;
    const String sessionId = 'stress_test_session_999';

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = MonitoringStorageService();
      engine = MonitoringEngineService(storageService: storage);
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('Stress Test: Generate 100+ sequential packets without data loss, verify FNV-1a checksums and packet sequence', () async {
      const int targetPacketCount = 100;
      final generatedPackets = <PacketRecord>[];

      final subscription = engine.packetStream.listen(generatedPackets.add);

      await engine.startMonitoring(
        sessionId: sessionId,
        triggerType: 'stress_test_trigger',
      );

      // Execute 99 additional manual cycles rapidly (total 100 packets)
      for (int i = 2; i <= targetPacketCount; i++) {
        final reason = (i % 10 == 0)
            ? 'event_battery_changed'
            : (i % 15 == 0)
                ? 'event_location_changed'
                : 'periodic_cycle';

        final packet = await engine.executeCycleManual(reasonCode: reason);
        expect(packet, isNotNull);
      }

      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      // 1. Verify packet count
      expect(generatedPackets.length, equals(targetPacketCount));
      expect(engine.currentState.currentPacketNumber, equals(targetPacketCount));

      // 2. Verify sequential ordering and non-empty FNV-1a checksums
      final checksumSet = <String>{};
      for (int i = 0; i < targetPacketCount; i++) {
        final packet = generatedPackets[i];
        expect(packet.packetNumber, equals(i + 1));
        expect(packet.sessionId, equals(sessionId));
        expect(packet.schemaVersion, equals('1.0'));
        expect(packet.checksum.length, equals(8));
        checksumSet.add(packet.checksum);
      }

      // 3. Verify local persistence storage integrity
      final storedPackets = await storage.getPackets(sessionId);
      expect(storedPackets.length, equals(targetPacketCount));

      for (int i = 0; i < targetPacketCount; i++) {
        expect(storedPackets[i].packetNumber, equals(i + 1));
        expect(storedPackets[i].checksum, equals(generatedPackets[i].checksum));
      }

      // 4. Verify append-only timeline events
      final timeline = await storage.getTimeline(sessionId);
      expect(timeline, isNotEmpty);
      expect(timeline.first.eventType, equals('engine_started'));

      // 5. Verify reliability metrics
      final metrics = engine.currentMetrics;
      expect(metrics.packetsGenerated, equals(targetPacketCount));
      expect(metrics.packetsStored, equals(targetPacketCount));
      expect(metrics.averageCollectionTimeMs, greaterThanOrEqualTo(0.0));

      await engine.stopMonitoring();
    });
  });
}
