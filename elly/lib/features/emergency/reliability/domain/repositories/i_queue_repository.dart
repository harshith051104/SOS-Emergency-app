/// i_queue_repository.dart
///
/// Interface for disk-backed emergency queue storage and item shedding.

library;

import '../entities/emergency_queue_item.dart';

abstract class IQeueueRepository {
  Future<void> enqueue(EmergencyQueueItem item);
  Future<List<EmergencyQueueItem>> getPendingQueue(String sessionId);
  Future<void> markCompleted(String itemId);
  Future<void> markFailed(String itemId);
  Future<void> purgeCompleted(String sessionId);
  Future<void> verifyAndRepairQueue(String sessionId);
}
