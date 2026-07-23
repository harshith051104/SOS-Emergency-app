/// delete_responder_usecase.dart
library;
import '../repositories/responder_repository.dart';

/// Permanently deletes the responder identified by [id].
class DeleteResponderUseCase {
  const DeleteResponderUseCase(this._repository);
  final ResponderRepository _repository;

  Future<void> call(String id) => _repository.deleteResponder(id);
}
