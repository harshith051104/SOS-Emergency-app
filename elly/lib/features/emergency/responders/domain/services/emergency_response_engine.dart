/// emergency_response_engine.dart
///
/// Abstract contract for the Emergency Response Engine.
///
/// The engine receives an [EmergencyEvent] + [EmergencyResponsePlan] and
/// orchestrates the full notification → acknowledgement → escalation loop.
///
/// It emits a [Stream] of [ResponseEngineUpdate] events so the UI can display
/// a live timeline without polling.
///
/// Phase 1: [MockEmergencyResponseEngine] provides realistic simulation.
/// Phase 2+: Replace or extend with real push/SMS/voice integrations.

library;

import '../entities/emergency_response_plan.dart';
import '../entities/response_engine_update.dart';
import '../../../sos/domain/entities/emergency_event.dart';

export '../entities/response_engine_update.dart';
export '../entities/emergency_response_plan.dart';

/// Contract for the Emergency Response Engine.
abstract class EmergencyResponseEngine {
  /// Execute the [plan] in response to [event].
  ///
  /// Emits [ResponseEngineUpdate] events as the engine:
  ///   1. Generates an emergency summary
  ///   2. Notifies each responder (in priority order)
  ///   3. Waits for acknowledgement
  ///   4. Escalates to the next responder on timeout
  ///   5. Completes when acknowledged or all responders are exhausted
  ///
  /// The stream closes when a terminal event ([completed]/[failed]/[cancelled])
  /// is emitted.
  Stream<ResponseEngineUpdate> execute({
    required EmergencyEvent event,
    required EmergencyResponsePlan plan,
  });

  /// Cancels the current execution.
  /// The stream will emit a [cancelled] event and then close.
  Future<void> cancel();
}
