/// communication_repository_impl.dart
///
/// Implementation of ICommunicationRepository.

library;

import '../../domain/entities/communication_request.dart';
import '../../domain/entities/communication_state.dart';
import '../../domain/entities/communication_event.dart';
import '../../domain/repositories/i_communication_repository.dart';
import '../services/communication_manager_service.dart';

class CommunicationRepositoryImpl implements ICommunicationRepository {
  CommunicationRepositoryImpl({
    required CommunicationManagerService service,
  }) : _service = service;

  final CommunicationManagerService _service;

  @override
  Stream<CommunicationState> get stateStream => _service.stateMachine.stateStream;

  @override
  Stream<CommunicationEvent> get eventStream => _service.eventBus.eventStream;

  @override
  CommunicationState get currentState => _service.stateMachine.currentState;

  @override
  Future<bool> sendCommunication(CommunicationRequest request) async {
    return await _service.sendCommunication(request);
  }
}
