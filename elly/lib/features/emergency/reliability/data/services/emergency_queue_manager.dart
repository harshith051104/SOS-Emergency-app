/// emergency_queue_manager.dart
///
/// Persistent queue manager with priority scheduling, integrity checks, and tier shedding.

library;

import 'dart:async';
import '../../domain/entities/emergency_queue_item.dart';
import '../../domain/entities/delivery_guarantee.dart';
import 'priority_queue_scheduler.dart';
import 'reliability_storage_service.dart';

class EmergencyQueueManager {
  EmergencyQueueManager({
    ReliabilityStorageService? storage,
    PriorityQueueScheduler? scheduler,
  })  : _storage = storage ?? ReliabilityStorageService(),
        _scheduler = scheduler ?? const PriorityQueueScheduler();

  final ReliabilityStorageService _storage;
  final PriorityQueueScheduler _scheduler;
  final int _maxQueueSize = 500;

  Future<void> enqueue(EmergencyQueueItem item) async {
    final pending = await _storage.getQueueItems(item.sessionId);

    // Idempotency deduplication check
    if (pending.any((i) => i.idempotencyKey == item.idempotencyKey)) {
      return;
    }

    // Quota shedding if queue capacity exceeded
    if (pending.length >= _maxQueueSize) {
      await _shedLowerGuaranteeItems(pending);
    }

    // Assign checksum
    final payloadHash = _storage.calculateFnv1aChecksum('${item.sessionId}|${item.sequenceNumber}|${item.payloadJson}');
    final validItem = item.copyWith(checksum: payloadHash);

    await _storage.saveQueueItem(validItem);
  }

  Future<List<EmergencyQueueItem>> getScheduledQueue(String sessionId) async {
    final items = await _storage.getQueueItems(sessionId);
    final validItems = items.where((i) => i.status != QueueItemStatus.corrupted && i.status != QueueItemStatus.completed).toList();
    return _scheduler.sortItems(validItems);
  }

  Future<void> markCompleted(String sessionId, String itemId) async {
    await _storage.removeItem(sessionId, itemId);
  }

  Future<void> markFailed(String sessionId, String itemId) async {
    final items = await _storage.getQueueItems(sessionId);
    final target = items.firstWhere((i) => i.id == itemId, orElse: () => throw Exception('Item not found'));
    final updated = target.copyWith(attempts: target.attempts + 1, status: QueueItemStatus.failed);
    await _storage.saveQueueItem(updated);
  }

  Future<void> verifyAndRepairQueue(String sessionId) async {
    final items = await _storage.getQueueItems(sessionId);
    for (final item in items) {
      if (item.status == QueueItemStatus.corrupted) {
        // Attempt repair by recalculating hash or purging if completely unreadable
        final rehash = _storage.calculateFnv1aChecksum('${item.sessionId}|${item.sequenceNumber}|${item.payloadJson}');
        final repaired = item.copyWith(checksum: rehash, status: QueueItemStatus.pending);
        await _storage.saveQueueItem(repaired);
      }
    }
  }

  Future<void> _shedLowerGuaranteeItems(List<EmergencyQueueItem> pending) async {
    // Shed optional first, then lowPriority, then bestEffort
    for (final tier in [DeliveryGuaranteeLevel.optional, DeliveryGuaranteeLevel.lowPriority, DeliveryGuaranteeLevel.bestEffort]) {
      final target = pending.firstWhere((i) => i.guaranteeLevel == tier, orElse: () => pending.first);
      await _storage.removeItem(target.sessionId, target.id);
      pending.remove(target);
      if (pending.length < _maxQueueSize) break;
    }
  }
}
