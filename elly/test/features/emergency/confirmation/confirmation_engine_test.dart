/// confirmation_engine_test.dart
///
/// Unit tests for RuleBasedConfirmationEngine, MockConfirmationEngine, and ConfirmationService.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/decision_engine/domain/entities/decision_recommendation.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_request.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_outcome.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_method.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/session_lifecycle_state.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/interruption_reason.dart';
import 'package:elly/features/emergency/confirmation/data/engines/rule_based_confirmation_engine.dart';
import 'package:elly/features/emergency/confirmation/data/engines/mock_confirmation_engine.dart';
import 'package:elly/features/emergency/confirmation/data/services/confirmation_service.dart';

void main() {
  group('ConfirmationEngine Unit Tests', () {
    late RuleBasedConfirmationEngine ruleEngine;
    late MockConfirmationEngine mockEngine;

    setUp(() {
      ruleEngine = RuleBasedConfirmationEngine();
      mockEngine = MockConfirmationEngine();
    });

    tearDown(() {
      ruleEngine.dispose();
      mockEngine.dispose();
    });

    test('MockConfirmationEngine returns mock confirmed result', () async {
      final request = ConfirmationRequest(
        sessionId: 'test_session_1',
        recommendation: DecisionRecommendation.requestConfirmation,
        emergencyConfidence: 0.90,
        timestamp: DateTime.now(),
      );

      final result = await mockEngine.evaluate(request);

      expect(result.sessionId, equals('test_session_1'));
      expect(result.confirmationOutcome, equals(ConfirmationOutcome.confirmed));
      expect(result.sessionLifecycleState, equals(SessionLifecycleState.confirmed));
      expect(result.confirmationMethod, equals(ConfirmationMethod.button));
    });

    test('RuleBasedConfirmationEngine evaluates normal/monitor as noConfirmationRequired', () async {
      final request = ConfirmationRequest(
        sessionId: 'normal_session',
        recommendation: DecisionRecommendation.normal,
        emergencyConfidence: 0.10,
        timestamp: DateTime.now(),
      );

      final result = await ruleEngine.evaluate(request);

      expect(result.confirmationOutcome, equals(ConfirmationOutcome.noConfirmationRequired));
      expect(result.sessionLifecycleState, equals(SessionLifecycleState.closed));
      expect(result.confirmationMethod, equals(ConfirmationMethod.none));
    });

    test('RuleBasedConfirmationEngine evaluates user cancellation response', () async {
      final request = ConfirmationRequest(
        sessionId: 'cancel_session',
        recommendation: DecisionRecommendation.requestConfirmation,
        emergencyConfidence: 0.85,
        userResponse: 'Cancel SOS',
        responseMethod: ConfirmationMethod.button,
        timestamp: DateTime.now(),
      );

      final result = await ruleEngine.evaluate(request);

      expect(result.confirmationOutcome, equals(ConfirmationOutcome.cancelled));
      expect(result.sessionLifecycleState, equals(SessionLifecycleState.cancelled));
      expect(result.confirmationMethod, equals(ConfirmationMethod.button));
    });

    test('RuleBasedConfirmationEngine evaluates user affirmative response', () async {
      final request = ConfirmationRequest(
        sessionId: 'confirm_session',
        recommendation: DecisionRecommendation.requestConfirmation,
        emergencyConfidence: 0.85,
        userResponse: 'Yes, help me!',
        responseMethod: ConfirmationMethod.voice,
        timestamp: DateTime.now(),
      );

      final result = await ruleEngine.evaluate(request);

      expect(result.confirmationOutcome, equals(ConfirmationOutcome.confirmed));
      expect(result.sessionLifecycleState, equals(SessionLifecycleState.confirmed));
      expect(result.confirmationMethod, equals(ConfirmationMethod.voice));
    });

    test('RuleBasedConfirmationEngine handles timeout state', () async {
      final request = ConfirmationRequest(
        sessionId: 'timeout_session',
        recommendation: DecisionRecommendation.requestConfirmation,
        emergencyConfidence: 0.85,
        wasTimedOut: true,
        timestamp: DateTime.now(),
      );

      final result = await ruleEngine.evaluate(request);

      expect(result.confirmationOutcome, equals(ConfirmationOutcome.timedOut));
      expect(result.sessionLifecycleState, equals(SessionLifecycleState.timedOut));
      expect(result.confirmationMethod, equals(ConfirmationMethod.autoTimeout));
    });

    test('RuleBasedConfirmationEngine handles interrupted state and interruptionReason', () async {
      final request = ConfirmationRequest(
        sessionId: 'interrupted_session',
        recommendation: DecisionRecommendation.requestConfirmation,
        emergencyConfidence: 0.85,
        wasInterrupted: true,
        interruptionReason: InterruptionReason.appKilled,
        timestamp: DateTime.now(),
      );

      final result = await ruleEngine.evaluate(request);

      expect(result.confirmationOutcome, equals(ConfirmationOutcome.interrupted));
      expect(result.sessionLifecycleState, equals(SessionLifecycleState.interrupted));
      expect(result.interruptionReason, equals(InterruptionReason.appKilled));
      expect(result.confirmationMethod, equals(ConfirmationMethod.none));
    });

    test('ConfirmationService records telemetry stats upon outcome evaluation', () async {
      final service = ConfirmationService(engine: mockEngine);

      final request = ConfirmationRequest(
        sessionId: 'telemetry_session',
        recommendation: DecisionRecommendation.requestConfirmation,
        emergencyConfidence: 0.90,
        timestamp: DateTime.now(),
      );

      await service.processRequest(request);

      expect(service.telemetry.confirmationCount, equals(1));
      expect(service.telemetry.confirmationRate, equals(100.0));
      expect(service.telemetry.failureCount, equals(0));
    });
  });
}
