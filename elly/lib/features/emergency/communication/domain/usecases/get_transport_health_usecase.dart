/// get_transport_health_usecase.dart
///
/// Use case retrieving transport health matrix.

library;

import '../entities/transport_health.dart';
import '../repositories/i_transport_repository.dart';

class GetTransportHealthUseCase {
  const GetTransportHealthUseCase(this._repository);

  final ITransportRepository _repository;

  Future<Map<String, TransportHealth>> execute() async {
    return await _repository.getTransportHealthMatrix();
  }
}
