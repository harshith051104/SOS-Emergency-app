/// select_optimal_transport_usecase.dart
///
/// Use case finding the optimal transport score.

library;

import '../entities/transport_score.dart';
import '../repositories/i_transport_repository.dart';

class SelectOptimalTransportUseCase {
  const SelectOptimalTransportUseCase(this._repository);

  final ITransportRepository _repository;

  Future<TransportScore> execute() async {
    return await _repository.getBestTransport();
  }
}
