/// start_reliability_engine_usecase.dart
///
/// Use case starting the Reliability Engine for an active session.

library;

import '../repositories/i_reliability_repository.dart';

class StartReliabilityEngineUseCase {
  const StartReliabilityEngineUseCase(this._repository);

  final IReliabilityRepository _repository;

  Future<void> execute({required String sessionId}) async {
    await _repository.startEngine(sessionId: sessionId);
  }
}
