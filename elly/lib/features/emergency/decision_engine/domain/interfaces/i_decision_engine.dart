/// i_decision_engine.dart
///
/// Interface defining the contract for Multi-Signal Emergency Decision Engines.

library;

import '../entities/emergency_decision_request.dart';
import '../entities/emergency_decision_result.dart';

abstract class DecisionEngine {
  /// Evaluates multi-modal evidence inputs and returns an explainable EmergencyDecisionResult.
  Future<EmergencyDecisionResult> evaluate(EmergencyDecisionRequest request);

  /// Releases resources allocated by the decision engine.
  void dispose();
}
