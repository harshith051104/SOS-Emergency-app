/// i_emergency_execution_engine.dart
///
/// Interface defining the contract for Emergency Execution Engines in Phase 8.

library;

import '../entities/emergency_session_request.dart';
import '../entities/emergency_session_result.dart';

abstract class EmergencyExecutionEngine {
  /// Executes the configured emergency workflow actions based on the request.
  Future<EmergencySessionResult> execute(EmergencySessionRequest request);

  /// Releases resources allocated by the execution engine.
  void dispose();
}
