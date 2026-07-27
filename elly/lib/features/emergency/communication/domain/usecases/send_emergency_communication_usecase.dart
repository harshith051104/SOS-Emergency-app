/// send_emergency_communication_usecase.dart
///
/// Use case sending an emergency communication request.

library;

import '../entities/communication_request.dart';
import '../repositories/i_communication_repository.dart';

class SendEmergencyCommunicationUseCase {
  const SendEmergencyCommunicationUseCase(this._repository);

  final ICommunicationRepository _repository;

  Future<bool> execute(CommunicationRequest request) async {
    return await _repository.sendCommunication(request);
  }
}
