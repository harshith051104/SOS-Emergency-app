/// i_communication_repository.dart
///
/// Primary repository interface for sending emergency communications and tracking state.

library;

import '../entities/communication_request.dart';
import '../entities/communication_state.dart';
import '../entities/communication_event.dart';

abstract class ICommunicationRepository {
  Stream<CommunicationState> get stateStream;
  Stream<CommunicationEvent> get eventStream;

  CommunicationState get currentState;

  Future<bool> sendCommunication(CommunicationRequest request);
}
