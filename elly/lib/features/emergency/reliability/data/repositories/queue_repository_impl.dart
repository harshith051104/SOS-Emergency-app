/// queue_repository_impl.dart
///
/// Implementation of IQeueueRepository.

library;

import '../../domain/entities/emergency_queue_item.dart';
import '../../domain/repositories/i_queue_repository.dart';
import '../services/emergency_queue_manager.dart';

class QueueRepositoryImpl implements IQeueueRepository {
  QueueRepositoryImpl({
    required EmergencyQueueManager queueManager,
  }) : _queueManager = queueManager;

  final EmergencyQueueManager _queueManager;

  @override
  Future<void> enqueue(EmergencyQueueItem item) async {
    await _queueManager.enqueue(item);
  }

  @override
  Future<List<EmergencyQueueItem>> getPendingQueue(String sessionId) async {
    return await _queueManager.getScheduledQueue(sessionId);
  }

  @override
  Future<void> markCompleted(String itemId) async {
    // Session context retrieved or passed
  }

  @override
  Future<void> markFailed(String itemId) async {
    // Failed marker logic
  }

  @override
  Future<void> purgeCompleted(String sessionId) async {
    // Purge completed payloads logic
  }

  @override
  Future<void> verifyAndRepairQueue(String sessionId) async {
    await _queueManager.verifyAndRepairQueue(sessionId);
  }
}
