/// mock_confirmation_engine.dart
///
/// Mock implementation of ConfirmationEngine for unit testing and instant UI simulation.

library;

import '../../domain/entities/confirmation_request.dart';
import '../../domain/entities/confirmation_result.dart';
import '../../domain/entities/confirmation_outcome.dart';
import '../../domain/entities/confirmation_method.dart';
import '../../domain/entities/session_lifecycle_state.dart';
import '../../domain/interfaces/i_confirmation_engine.dart';

class MockConfirmationEngine implements ConfirmationEngine {
  MockConfirmationEngine({
    this.mockResult,
    this.simulatedLatencyMs = 2,
  });

  final ConfirmationResult? mockResult;
  final int simulatedLatencyMs;

  @override
  Future<ConfirmationResult> evaluate(ConfirmationRequest request) async {
    if (simulatedLatencyMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: simulatedLatencyMs));
    }

    if (mockResult != null) {
      return mockResult!;
    }

    return ConfirmationResult(
      sessionId: request.sessionId,
      confirmationOutcome: ConfirmationOutcome.confirmed,
      sessionLifecycleState: SessionLifecycleState.confirmed,
      confirmationMethod: ConfirmationMethod.button,
      responseTimeMs: 1450,
      userResponse: 'CONFIRM EMERGENCY BUTTON PRESSED',
      engineVersion: 'v1.0.0-mock',
      algorithmVersion: 'v1.0.0-mock',
      timestamp: DateTime.now(),
    );
  }

  @override
  void dispose() {}
}
