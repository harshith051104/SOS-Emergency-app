/// get_responders_usecase.dart
library;
import '../entities/responder.dart';
import '../repositories/responder_repository.dart';

/// Returns all configured responders in priority order.
class GetRespondersUseCase {
  const GetRespondersUseCase(this._repository);
  final ResponderRepository _repository;

  Future<List<Responder>> call() => _repository.getResponders();
}
