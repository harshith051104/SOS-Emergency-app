/// reorder_responders_usecase.dart
library;
import '../repositories/responder_repository.dart';

/// Updates the priority of all responders to match [orderedIds].
/// The first ID receives priority 0 (notified first during an emergency).
class ReorderRespondersUseCase {
  const ReorderRespondersUseCase(this._repository);
  final ResponderRepository _repository;

  Future<void> call(List<String> orderedIds) =>
      _repository.reorderResponders(orderedIds);
}
