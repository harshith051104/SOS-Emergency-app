/// monitoring_engine_service_test.dart
///
/// Integration tests for MonitoringEngineService execution lifecycle, restart recovery, and adaptive intervals.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/monitoring_state.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/monitoring_config.dart';
import 'package:elly/features/emergency/monitoring/data/services/monitoring_engine_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonitoringEngineService', () {
    late MonitoringEngineService engine;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      engine = MonitoringEngineService();
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('should start monitoring, execute initial cycle, and transition state to active', () async {
      expect(engine.currentState.status, equals(MonitoringStatus.idle));

      await engine.startMonitoring(
        sessionId: 'session_engine_test_1',
        triggerType: 'manual_sos',
        config: const MonitoringConfig(
          normalInterval: Duration(milliseconds: 500),
        ),
      );

      expect(engine.currentState.status, equals(MonitoringStatus.active));
      expect(engine.currentState.sessionId, equals('session_engine_test_1'));
      expect(engine.currentState.currentPacketNumber, equals(1));
      expect(engine.currentTimeline.length, greaterThanOrEqualTo(1));

      await engine.stopMonitoring();
      expect(engine.currentState.status, equals(MonitoringStatus.idle));
    });

    test('should execute manual forced telemetry cycle with custom reason code', () async {
      await engine.startMonitoring(
        sessionId: 'session_engine_test_2',
        triggerType: 'manual_sos',
      );

      final packet = await engine.executeCycleManual(reasonCode: 'custom_alert_triggered');
      expect(packet, isNotNull);
      expect(packet!.reasonCode, equals('custom_alert_triggered'));
      expect(packet.packetNumber, equals(2));

      await engine.stopMonitoring();
    });

    test('should auto-recover active session after simulated app restart', () async {
      // 1. Start initial session and generate 2 packets
      await engine.startMonitoring(
        sessionId: 'session_to_recover_123',
        triggerType: 'manual_sos',
      );
      await engine.executeCycleManual(reasonCode: 'battery_changed');

      expect(engine.currentState.currentPacketNumber, equals(2));

      // Simulate app kill without calling stop (leaving session active in storage)
      final storageService = MonitoringEngineService();

      // 2. Launch recovery on new service instance
      final recoveryInfo = await storageService.recoverActiveSession();

      expect(recoveryInfo.hasActiveSession, isTrue);
      expect(recoveryInfo.sessionMetadata!.sessionId, equals('session_to_recover_123'));

      // Packet counter should continue seamlessly
      expect(storageService.currentState.currentPacketNumber, equals(3));
      expect(storageService.currentTimeline.any((e) => e.eventType == 'session_recovered'), isTrue);

      await storageService.stopMonitoring();
      await storageService.dispose();
    });
  });
}
