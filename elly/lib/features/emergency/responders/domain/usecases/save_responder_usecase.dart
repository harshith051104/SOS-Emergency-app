/// save_responder_usecase.dart
library;
import '../entities/responder.dart';
import '../repositories/responder_repository.dart';

/// Inserts or updates a [Responder]. Returns the saved instance.
class SaveResponderUseCase {
  const SaveResponderUseCase(this._repository);
  final ResponderRepository _repository;

  Future<Responder> call(Responder responder) =>
      _repository.saveResponder(responder);
}
