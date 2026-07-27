/// offline_packet.dart
///
/// Immutable domain model representing one queued EmergencyDataPacket wrapper in local offline storage.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/packet/domain/entities/emergency_data_packet.dart';

@immutable
class OfflinePacket {
  const OfflinePacket({
    required this.queueId,
    required this.packetId,
    required this.sequenceNumber,
    required this.createdAt,
    this.retryCount = 0,
    required this.priority,
    required this.packetStatus,
    this.failureReason,
    this.nextRetryAt,
    required this.packet,
  });

  final String queueId;
  final String packetId;
  final int sequenceNumber;
  final DateTime createdAt;
  final int retryCount;
  final PacketPriority priority;
  final PacketStatus packetStatus;
  final String? failureReason;
  final DateTime? nextRetryAt;
  final EmergencyDataPacket packet;

  OfflinePacket copyWith({
    String? queueId,
    String? packetId,
    int? sequenceNumber,
    DateTime? createdAt,
    int? retryCount,
    PacketPriority? priority,
    PacketStatus? packetStatus,
    String? failureReason,
    DateTime? nextRetryAt,
    EmergencyDataPacket? packet,
  }) {
    return OfflinePacket(
      queueId: queueId ?? this.queueId,
      packetId: packetId ?? this.packetId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      priority: priority ?? this.priority,
      packetStatus: packetStatus ?? this.packetStatus,
      failureReason: failureReason ?? this.failureReason,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      packet: packet ?? this.packet,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'queueId': queueId,
      'packetId': packetId,
      'sequenceNumber': sequenceNumber,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'priority': priority.name,
      'packetStatus': packetStatus.name,
      'failureReason': failureReason,
      'nextRetryAt': nextRetryAt?.toIso8601String(),
      'packet': packet.toJson(),
    };
  }

  factory OfflinePacket.fromJson(Map<String, dynamic> json) {
    return OfflinePacket(
      queueId: json['queueId'] as String,
      packetId: json['packetId'] as String,
      sequenceNumber: json['sequenceNumber'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      priority: PacketPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => PacketPriority.critical,
      ),
      packetStatus: PacketStatus.values.firstWhere(
        (e) => e.name == json['packetStatus'],
        orElse: () => PacketStatus.queued,
      ),
      failureReason: json['failureReason'] as String?,
      nextRetryAt: json['nextRetryAt'] != null ? DateTime.parse(json['nextRetryAt'] as String) : null,
      packet: EmergencyDataPacket.fromJson(Map<String, dynamic>.from(json['packet'] as Map)),
    );
  }
}
