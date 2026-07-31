/// decision_controller_test.dart
///
/// Unit tests for DecisionController state management, Riverpod integration, and evidence timeline logging.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/decision_engine/domain/entities/emergency_decision_request.dart';
import 'package:elly/features/emergency/decision_engine/domain/entities/decision_state.dart';
import 'package:elly/features/emergency/decision_engine/presentation/providers/decision_providers.dart';

void main() {
  group('DecisionController Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is idle', () {
      final state = container.read(decisionControllerProvider);
      expect(state.status, equals(DecisionStatus.idle));
      expect(state.lastResult, isNull);
      expect(state.activeSessionId, isNull);
      expect(state.evidenceTimeline, isEmpty);
    });

    test('evaluateDecision executes evaluation and updates state to completed', () async {
      final controller = container.read(decisionControllerProvider.notifier);

      final request = EmergencyDecisionRequest(
        sessionId: 'controller_test_1',
        timestamp: DateTime.now(),
      );

      await controller.evaluateDecision(request);

      final state = container.read(decisionControllerProvider);
      expect(state.status, equals(DecisionStatus.completed));
      expect(state.lastResult, isNotNull);
      expect(state.lastResult?.sessionId, equals('controller_test_1'));
      expect(state.lastResult?.engineVersion, isNotEmpty);
      expect(state.lastResult?.algorithmVersion, isNotEmpty);
      expect(state.evidenceTimeline, isNotEmpty);
    });
  });
}
