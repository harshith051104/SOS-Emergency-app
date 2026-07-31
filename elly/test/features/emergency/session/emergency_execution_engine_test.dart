/// emergency_execution_engine_test.dart
///
/// Unit tests for RuleBasedExecutionEngine, MockExecutionEngine, and EmergencySessionService.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_result.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_outcome.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_method.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/session_lifecycle_state.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_session_request.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_session_result.dart';
import 'package:elly/features/emergency/session/domain/entities/acknowledgement_status.dart';

import 'package:elly/features/emergency/session/domain/interfaces/emergency_action.dart';
import 'package:elly/features/emergency/session/data/actions/send_sms_action.dart';
import 'package:elly/features/emergency/session/data/actions/phone_call_action.dart';
import 'package:elly/features/emergency/session/data/actions/location_sharing_action.dart';
import 'package:elly/features/emergency/session/data/actions/medical_profile_action.dart';
import 'package:elly/features/emergency/session/data/actions/emergency_timeline_action.dart';
import 'package:elly/features/emergency/session/data/actions/emergency_notification_action.dart';
import 'package:elly/features/emergency/session/data/engines/rule_based_execution_engine.dart';
import 'package:elly/features/emergency/session/data/engines/mock_execution_engine.dart';
import 'package:elly/features/emergency/session/data/services/emergency_session_service.dart';

void main() {
  group('EmergencyExecutionEngine Unit Tests', () {
    late List<EmergencyAction> actions;
    late RuleBasedExecutionEngine ruleEngine;
    late MockExecutionEngine mockEngine;

    setUp(() {
      actions = [
        SendSmsAction(),
        PhoneCallAction(),
        LocationSharingAction(),
        MedicalProfileAction(),
        EmergencyTimelineAction(),
        EmergencyNotificationAction(),
      ];
      ruleEngine = RuleBasedExecutionEngine(actions: actions);
      mockEngine = MockExecutionEngine();
    });

    tearDown(() {
      ruleEngine.dispose();
      mockEngine.dispose();
    });

    test('MockExecutionEngine returns completed mock result', () async {
      final confResult = ConfirmationResult(
        sessionId: 'test_session_1',
        confirmationOutcome: ConfirmationOutcome.confirmed,
        sessionLifecycleState: SessionLifecycleState.confirmed,
        confirmationMethod: ConfirmationMethod.button,
        responseTimeMs: 120,
        timestamp: DateTime.now(),
      );

      final request = EmergencySessionRequest(
        sessionId: 'test_session_1',
        confirmationResult: confResult,
        emergencyConfidence: 0.95,
        confirmationOutcome: ConfirmationOutcome.confirmed,
        timestamp: DateTime.now(),
      );

      final result = await mockEngine.execute(request);

      expect(result.sessionId, equals('test_session_1'));
      expect(result.sessionState, equals(SessionState.completed));
      expect(result.executedActions, hasLength(6));
      expect(result.successfulActions, hasLength(6));
      expect(result.acknowledgementStatus, equals(AcknowledgementStatus.acknowledged));
    });

    test('RuleBasedExecutionEngine executes all pluggable actions sequentially for confirmed outcome', () async {
      final now = DateTime.now();
      final confResult = ConfirmationResult(
        sessionId: 'exec_session_1',
        confirmationOutcome: ConfirmationOutcome.confirmed,
        sessionLifecycleState: SessionLifecycleState.confirmed,
        confirmationMethod: ConfirmationMethod.voice,
        responseTimeMs: 150,
        timestamp: now,
      );

      final request = EmergencySessionRequest(
        sessionId: 'exec_session_1',
        confirmationResult: confResult,
        emergencyConfidence: 0.92,
        confirmationOutcome: ConfirmationOutcome.confirmed,
        timestamp: now,
      );

      final result = await ruleEngine.execute(request);

      expect(result.sessionId, equals('exec_session_1'));
      expect(result.sessionState, equals(SessionState.completed));
      expect(result.executedActions, containsAll(['send_sms', 'phone_call', 'location_sharing', 'medical_profile', 'emergency_timeline', 'emergency_notification']));
      expect(result.successfulActions, hasLength(6));
      expect(result.failedActions, isEmpty);
      expect(result.acknowledgementStatus, equals(AcknowledgementStatus.acknowledged));
    });

    test('RuleBasedExecutionEngine returns cancelled sessionState when confirmation was cancelled', () async {
      final now = DateTime.now();
      final confResult = ConfirmationResult(
        sessionId: 'cancel_session_1',
        confirmationOutcome: ConfirmationOutcome.cancelled,
        sessionLifecycleState: SessionLifecycleState.cancelled,
        confirmationMethod: ConfirmationMethod.button,
        responseTimeMs: 200,
        timestamp: now,
      );

      final request = EmergencySessionRequest(
        sessionId: 'cancel_session_1',
        confirmationResult: confResult,
        emergencyConfidence: 0.90,
        confirmationOutcome: ConfirmationOutcome.cancelled,
        timestamp: now,
      );

      final result = await ruleEngine.execute(request);

      expect(result.sessionState, equals(SessionState.cancelled));
      expect(result.executedActions, isEmpty);
    });

    test('EmergencySessionService tracks telemetry stats upon session completion', () async {
      final service = EmergencySessionService(engine: mockEngine);

      final confResult = ConfirmationResult(
        sessionId: 'telemetry_session_1',
        confirmationOutcome: ConfirmationOutcome.confirmed,
        sessionLifecycleState: SessionLifecycleState.confirmed,
        confirmationMethod: ConfirmationMethod.button,
        responseTimeMs: 100,
        timestamp: DateTime.now(),
      );

      final request = EmergencySessionRequest(
        sessionId: 'telemetry_session_1',
        confirmationResult: confResult,
        emergencyConfidence: 0.95,
        confirmationOutcome: ConfirmationOutcome.confirmed,
        timestamp: DateTime.now(),
      );

      await service.processRequest(request);

      expect(service.telemetry.sessionsStarted, equals(1));
      expect(service.telemetry.sessionsCompleted, equals(1));
      expect(service.telemetry.successfulActionsCount, equals(6));
    });
  });
}
