/// communication_result.dart
///
/// Dispatch result DTO summarizing channel delivery status, failure reasons, and timestamps.

library;

import 'package:flutter/foundation.dart';

enum DeliveryStatus {
  sent,
  delivered,
  failed,
  queuedOffline,
}

@immutable
class CommunicationResult {
  const CommunicationResult({
    required this.requestId,
    required this.channelUsed,
    required this.status,
    this.failureReason,
    required this.retryCount,
    required this.timestamp,
  });

  final String requestId;
  final String channelUsed;
  final DeliveryStatus status;
  final String? failureReason;
  final int retryCount;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'channelUsed': channelUsed,
        'status': status.name,
        'failureReason': failureReason,
        'retryCount': retryCount,
        'timestamp': timestamp.toIso8601String(),
      };
}
