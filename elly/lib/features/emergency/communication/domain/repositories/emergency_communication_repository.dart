/// emergency_communication_repository.dart
///
/// Pure domain contract for the Emergency Communication Repository.
/// Strictly decoupled from platform SDKs, UI widgets, and Riverpod.

library;

import '../entities/emergency_dispatch_request.dart';
import '../entities/dispatch_result.dart';
import '../entities/communication_event.dart';

abstract interface class EmergencyCommunicationRepository {
  /// Initiates end-to-end emergency communication dispatch workflow.
  Future<DispatchResult> startEmergencyCommunication(EmergencyDispatchRequest request);

  /// Triggers notification dispatches to registered SOS Circle contacts.
  Future<void> notifySOSCircle(EmergencyDispatchRequest request);

  /// Executes telemetry compilation and pre-dispatch setup.
  Future<void> prepareDispatch(EmergencyDispatchRequest request);

  /// Concludes active communication session.
  Future<void> endCommunication(String sessionId);

  /// Broadcast stream of real-time communication events.
  Stream<CommunicationEvent> get eventStream;
}
