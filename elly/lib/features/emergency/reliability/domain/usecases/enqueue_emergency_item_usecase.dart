/// enqueue_emergency_item_usecase.dart
///
/// Use case adding a transport-agnostic item to the persistent emergency queue.

library;

import '../entities/emergency_queue_item.dart';
import '../repositories/i_queue_repository.dart';

class EnqueueEmergencyItemUseCase {
  const EnqueueEmergencyItemUseCase(this._repository);

  final IQeueueRepository _repository;

  Future<void> execute(EmergencyQueueItem item) async {
    await _repository.enqueue(item);
  }
}
