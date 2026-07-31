/// i_confirmation_engine.dart
///
/// Interface defining the contract for Human Interaction Confirmation Engines.

library;

import '../entities/confirmation_request.dart';
import '../entities/confirmation_result.dart';

abstract class ConfirmationEngine {
  /// Evaluates user responses, countdown states, or strategy conditions and returns a ConfirmationResult.
  Future<ConfirmationResult> evaluate(ConfirmationRequest request);

  /// Releases resources allocated by the confirmation engine.
  void dispose();
}
