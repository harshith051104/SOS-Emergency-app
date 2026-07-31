/// emergency_session_controller_test.dart
///
/// Unit tests for EmergencySessionController state management and Riverpod integration.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_result.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_outcome.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_method.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/session_lifecycle_state.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_session_state.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_session_result.dart';
import 'package:elly/features/emergency/session/presentation/providers/session_providers.dart';

void main() {
  group('EmergencySessionController Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is idle', () {
      final state = container.read(activeEmergencySessionControllerProvider);
      expect(state.status, equals(EmergencySessionStatus.idle));
      expect(state.lastResult, isNull);
      expect(state.activeSessionId, isNull);
      expect(state.executionTimeline, isEmpty);
    });

    test('startSession executes action pipeline and updates state to completed', () async {
      final controller = container.read(activeEmergencySessionControllerProvider.notifier);

      final confResult = ConfirmationResult(
        sessionId: 'controller_test_1',
        confirmationOutcome: ConfirmationOutcome.confirmed,
        sessionLifecycleState: SessionLifecycleState.confirmed,
        confirmationMethod: ConfirmationMethod.button,
        responseTimeMs: 120,
        timestamp: DateTime.now(),
      );

      await controller.startSession(
        sessionId: 'controller_test_1',
        confirmationResult: confResult,
        emergencyConfidence: 0.95,
        confirmationOutcome: ConfirmationOutcome.confirmed,
      );

      final state = container.read(activeEmergencySessionControllerProvider);
      expect(state.status, equals(EmergencySessionStatus.completed));
      expect(state.lastResult, isNotNull);
      expect(state.lastResult?.sessionId, equals('controller_test_1'));
      expect(state.lastResult?.sessionState, equals(SessionState.completed));
      expect(state.lastResult?.successfulActions, hasLength(6));
      expect(state.executionTimeline, isNotEmpty);
    });
  });
}
