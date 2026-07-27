/// stop_reliability_engine_usecase.dart
///
/// Use case stopping the Reliability Engine.

library;

import '../repositories/i_reliability_repository.dart';

class StopReliabilityEngineUseCase {
  const StopReliabilityEngineUseCase(this._repository);

  final IReliabilityRepository _repository;

  Future<void> execute() async {
    await _repository.stopEngine();
  }
}
