/// confirmation_controller_test.dart
///
/// Unit tests for ConfirmationController state management, Riverpod integration, and countdown timers.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/decision_engine/domain/entities/decision_recommendation.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_state.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_outcome.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/session_lifecycle_state.dart';
import 'package:elly/features/emergency/confirmation/presentation/providers/confirmation_providers.dart';

void main() {
  group('ConfirmationController Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is idle', () {
      final state = container.read(confirmationControllerProvider);
      expect(state.status, equals(ConfirmationStatus.idle));
      expect(state.sessionLifecycleState, equals(SessionLifecycleState.created));
      expect(state.lastResult, isNull);
      expect(state.activeSessionId, isNull);
      expect(state.remainingSeconds, equals(0));
    });

    test('startConfirmationFlow initializes strategy and countdown timer for REQUEST_CONFIRMATION', () {
      final controller = container.read(confirmationControllerProvider.notifier);

      controller.startConfirmationFlow(
        sessionId: 'test_flow_1',
        recommendation: DecisionRecommendation.requestConfirmation,
        confidence: 0.90,
      );

      final state = container.read(confirmationControllerProvider);
      expect(state.status, equals(ConfirmationStatus.waiting));
      expect(state.sessionLifecycleState, equals(SessionLifecycleState.waitingForConfirmation));
      expect(state.activeStrategy.name, equals('REQUEST_CONFIRMATION'));
      expect(state.remainingSeconds, equals(10));
    });

    test('confirmUserResponse evaluates user confirmation and updates state', () async {
      final controller = container.read(confirmationControllerProvider.notifier);

      controller.startConfirmationFlow(
        sessionId: 'test_flow_2',
        recommendation: DecisionRecommendation.requestConfirmation,
        confidence: 0.90,
      );

      controller.cancelConfirmation();

      final state = container.read(confirmationControllerProvider);
      expect(state.status, equals(ConfirmationStatus.cancelled));
      expect(state.sessionLifecycleState, equals(SessionLifecycleState.cancelled));
      expect(state.lastResult, isNotNull);
      expect(state.lastResult?.confirmationOutcome, equals(ConfirmationOutcome.cancelled));
    });
  });
}
