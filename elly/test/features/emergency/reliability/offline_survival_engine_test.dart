/// offline_survival_engine_test.dart
///
/// Integration tests for OfflineSurvivalEngine.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elly/features/emergency/reliability/domain/entities/reliability_state.dart';
import 'package:elly/features/emergency/reliability/data/services/offline_survival_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineSurvivalEngine', () {
    late OfflineSurvivalEngine engine;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      engine = OfflineSurvivalEngine();
    });

    tearDown(() async {
      await engine.stopEngine();
    });

    test('should initialize and start engine cleanly', () async {
      await engine.startEngine(sessionId: 'TEST_RELIABILITY_SESS_1');
      expect(engine.stateMachine.currentState.sessionId, equals('TEST_RELIABILITY_SESS_1'));
      expect(engine.stateMachine.currentState.status, isNot(equals(ReliabilityStatus.idle)));
    });

    test('should enqueue packet into queue without throwing', () async {
      await engine.startEngine(sessionId: 'TEST_RELIABILITY_SESS_2');
      await engine.enqueuePacket(payloadJson: '{"packetNumber":1}');
      expect(engine.stateMachine.currentState, isNotNull);
    });
  });
}
