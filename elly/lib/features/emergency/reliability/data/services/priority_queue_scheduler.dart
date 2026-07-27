/// priority_queue_scheduler.dart
///
/// Service sorting queue items by priority level first, then sequence number.

library;

import '../../domain/entities/emergency_queue_item.dart';
import '../../domain/entities/queue_priority.dart';

class PriorityQueueScheduler {
  const PriorityQueueScheduler();

  List<EmergencyQueueItem> sortItems(List<EmergencyQueueItem> items) {
    final list = List<EmergencyQueueItem>.from(items);

    list.sort((a, b) {
      final pA = _priorityWeight(a.priority);
      final pB = _priorityWeight(b.priority);
      if (pA != pB) {
        return pA.compareTo(pB); // Lower number = higher priority
      }
      return a.sequenceNumber.compareTo(b.sequenceNumber);
    });

    return list;
  }

  int _priorityWeight(QueuePriority priority) {
    switch (priority) {
      case QueuePriority.critical:
        return 1;
      case QueuePriority.high:
        return 2;
      case QueuePriority.medium:
        return 3;
      case QueuePriority.low:
        return 4;
    }
  }
}
