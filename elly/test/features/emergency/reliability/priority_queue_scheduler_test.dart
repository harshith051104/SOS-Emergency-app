/// priority_queue_scheduler_test.dart
///
/// Unit tests for PriorityQueueScheduler.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/reliability/domain/entities/emergency_queue_item.dart';
import 'package:elly/features/emergency/reliability/domain/entities/queue_priority.dart';
import 'package:elly/features/emergency/reliability/domain/entities/delivery_guarantee.dart';
import 'package:elly/features/emergency/reliability/domain/entities/transport_config.dart';
import 'package:elly/features/emergency/reliability/data/services/priority_queue_scheduler.dart';

void main() {
  group('PriorityQueueScheduler', () {
    const scheduler = PriorityQueueScheduler();

    test('should sort items strictly by Priority Level first, then sequence number', () {
      final now = DateTime.now();
      final itemLow = EmergencyQueueItem(
        id: '1',
        sessionId: 'sess_1',
        sequenceNumber: 1,
        itemType: 'debug',
        payloadJson: '{}',
        idempotencyKey: 'k1',
        priority: QueuePriority.low,
        guaranteeLevel: DeliveryGuaranteeLevel.optional,
        transportConfig: TransportConfig.defaultHttpWithSmsFallback(),
        attempts: 0,
        createdAt: now,
        status: QueueItemStatus.pending,
        checksum: '12345678',
      );

      final itemCritical = EmergencyQueueItem(
        id: '2',
        sessionId: 'sess_1',
        sequenceNumber: 5,
        itemType: 'packet',
        payloadJson: '{}',
        idempotencyKey: 'k2',
        priority: QueuePriority.critical,
        guaranteeLevel: DeliveryGuaranteeLevel.mustDeliver,
        transportConfig: TransportConfig.defaultHttpWithSmsFallback(),
        attempts: 0,
        createdAt: now,
        status: QueueItemStatus.pending,
        checksum: '12345678',
      );

      final itemHigh = EmergencyQueueItem(
        id: '3',
        sessionId: 'sess_1',
        sequenceNumber: 2,
        itemType: 'location',
        payloadJson: '{}',
        idempotencyKey: 'k3',
        priority: QueuePriority.high,
        guaranteeLevel: DeliveryGuaranteeLevel.mustDeliver,
        transportConfig: TransportConfig.defaultHttpWithSmsFallback(),
        attempts: 0,
        createdAt: now,
        status: QueueItemStatus.pending,
        checksum: '12345678',
      );

      final sorted = scheduler.sortItems([itemLow, itemCritical, itemHigh]);

      expect(sorted[0].id, equals('2')); // Critical first
      expect(sorted[1].id, equals('3')); // High second
      expect(sorted[2].id, equals('1')); // Low last
    });
  });
}
