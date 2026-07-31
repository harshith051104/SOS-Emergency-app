/// rule_based_confirmation_engine.dart
///
/// Deterministic rule engine evaluating confirmation requests, user responses,
/// countdown timeouts, and app interruption states.

library;

import 'package:elly/features/emergency/decision_engine/domain/entities/decision_recommendation.dart';
import '../../domain/entities/confirmation_request.dart';
import '../../domain/entities/confirmation_result.dart';
import '../../domain/entities/confirmation_outcome.dart';
import '../../domain/entities/confirmation_method.dart';
import '../../domain/entities/session_lifecycle_state.dart';
import '../../domain/entities/interruption_reason.dart';
import '../../domain/interfaces/i_confirmation_engine.dart';

class RuleBasedConfirmationEngine implements ConfirmationEngine {
  static const String engineVersionConst = 'v1.0.0-rules';
  static const String algorithmVersionConst = 'v1.0.0-strategy';

  @override
  Future<ConfirmationResult> evaluate(ConfirmationRequest request) async {
    final stopwatch = Stopwatch()..start();
    final now = DateTime.now();

    ConfirmationOutcome outcome = ConfirmationOutcome.noConfirmationRequired;
    SessionLifecycleState lifecycle = SessionLifecycleState.closed;
    ConfirmationMethod method = request.responseMethod ?? ConfirmationMethod.none;
    InterruptionReason interruptionReason = request.interruptionReason;

    // 1. Check for Interrupted state
    if (request.wasInterrupted) {
      outcome = ConfirmationOutcome.interrupted;
      lifecycle = SessionLifecycleState.interrupted;
      method = ConfirmationMethod.none;
      if (interruptionReason == InterruptionReason.none) {
        interruptionReason = InterruptionReason.unknown;
      }
    }
    // 2. Check for Timed Out state
    else if (request.wasTimedOut) {
      outcome = ConfirmationOutcome.timedOut;
      lifecycle = SessionLifecycleState.timedOut;
      method = ConfirmationMethod.autoTimeout;
    }
    // 3. Check for User Response (Voice or Button)
    else if (request.userResponse != null && request.userResponse!.isNotEmpty) {
      final responseClean = request.userResponse!.trim().toLowerCase();

      if (_isCancellationResponse(responseClean)) {
        outcome = ConfirmationOutcome.cancelled;
        lifecycle = SessionLifecycleState.cancelled;
      } else {
        outcome = ConfirmationOutcome.confirmed;
        lifecycle = SessionLifecycleState.confirmed;
      }
    }
    // 4. Baseline recommendation check
    else if (request.recommendation == DecisionRecommendation.normal ||
        request.recommendation == DecisionRecommendation.monitor) {
      outcome = ConfirmationOutcome.noConfirmationRequired;
      lifecycle = SessionLifecycleState.closed;
      method = ConfirmationMethod.none;
    }

    stopwatch.stop();

    return ConfirmationResult(
      sessionId: request.sessionId,
      confirmationOutcome: outcome,
      sessionLifecycleState: lifecycle,
      confirmationMethod: method,
      responseTimeMs: stopwatch.elapsedMilliseconds,
      interruptionReason: interruptionReason,
      timestamp: now,
    );
  }

  bool _isCancellationResponse(String text) {
    const cancelKeywords = ['cancel', 'no', 'okay', "i'm okay", 'false alarm', 'stop', 'mistake', 'dismiss'];
    for (final kw in cancelKeywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  @override
  void dispose() {}
}
