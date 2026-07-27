/// get_reliability_status_usecase.dart
///
/// Use case accessing current reliability state and score.

library;

import '../entities/reliability_state.dart';
import '../entities/reliability_score.dart';
import '../repositories/i_reliability_repository.dart';

class GetReliabilityStatusUseCase {
  const GetReliabilityStatusUseCase(this._repository);

  final IReliabilityRepository _repository;

  ReliabilityState get currentState => _repository.currentState;
  ReliabilityScore get currentScore => _repository.currentScore;
  Stream<ReliabilityState> get stateStream => _repository.stateStream;
}
