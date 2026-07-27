/// recover_reliability_session_usecase.dart
///
/// Use case triggering session restart recovery.

library;

import '../repositories/i_reliability_repository.dart';

class RecoverReliabilitySessionUseCase {
  const RecoverReliabilitySessionUseCase(this._repository);

  final IReliabilityRepository _repository;

  Future<void> execute() async {
    await _repository.recoverSession();
  }
}
