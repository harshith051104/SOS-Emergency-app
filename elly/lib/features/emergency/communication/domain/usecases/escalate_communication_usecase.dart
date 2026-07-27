/// escalate_communication_usecase.dart
///
/// Use case executing multi-step transport escalation.

library;

import '../entities/communication_request.dart';
import '../repositories/i_communication_repository.dart';

class EscalateCommunicationUseCase {
  const EscalateCommunicationUseCase(this._repository);

  final ICommunicationRepository _repository;

  Future<bool> execute(CommunicationRequest request) async {
    return await _repository.sendCommunication(request);
  }
}
