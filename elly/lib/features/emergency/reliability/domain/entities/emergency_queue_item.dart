/// emergency_queue_item.dart
///
/// Persistent transport-agnostic queue entry domain model.

library;

import 'package:equatable/equatable.dart';
import 'queue_priority.dart';
import 'delivery_guarantee.dart';
import 'transport_config.dart';

enum QueueItemStatus {
  pending,
  transmitting,
  completed,
  failed,
  corrupted,
}

class EmergencyQueueItem extends Equatable {
  const EmergencyQueueItem({
    required this.id,
    required this.sessionId,
    required this.sequenceNumber,
    required this.itemType,
    required this.payloadJson,
    required this.idempotencyKey,
    required this.priority,
    required this.guaranteeLevel,
    required this.transportConfig,
    required this.attempts,
    required this.createdAt,
    required this.status,
    required this.checksum,
  });

  final String id;
  final String sessionId;
  final int sequenceNumber;
  final String itemType; // 'packet', 'timeline', 'disconnect_log'
  final String payloadJson;
  final String idempotencyKey;
  final QueuePriority priority;
  final DeliveryGuaranteeLevel guaranteeLevel;
  final TransportConfig transportConfig;
  final int attempts;
  final DateTime createdAt;
  final QueueItemStatus status;
  final String checksum;

  EmergencyQueueItem copyWith({
    String? id,
    String? sessionId,
    int? sequenceNumber,
    String? itemType,
    String? payloadJson,
    String? idempotencyKey,
    QueuePriority? priority,
    DeliveryGuaranteeLevel? guaranteeLevel,
    TransportConfig? transportConfig,
    int? attempts,
    DateTime? createdAt,
    QueueItemStatus? status,
    String? checksum,
  }) {
    return EmergencyQueueItem(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      itemType: itemType ?? this.itemType,
      payloadJson: payloadJson ?? this.payloadJson,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      priority: priority ?? this.priority,
      guaranteeLevel: guaranteeLevel ?? this.guaranteeLevel,
      transportConfig: transportConfig ?? this.transportConfig,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      checksum: checksum ?? this.checksum,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        sequenceNumber,
        itemType,
        payloadJson,
        idempotencyKey,
        priority,
        guaranteeLevel,
        transportConfig,
        attempts,
        createdAt,
        status,
        checksum,
      ];
}
