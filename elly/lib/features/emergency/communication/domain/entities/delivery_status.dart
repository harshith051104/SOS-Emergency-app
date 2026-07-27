/// delivery_status.dart
///
/// Delivery lifecycle tracking entity for end-to-end receipt auditing.

library;

import 'package:equatable/equatable.dart';

enum DeliveryState {
  queued,
  sending,
  delivered,
  acknowledged,
  failed,
  escalated,
}

class DeliveryStatus extends Equatable {
  const DeliveryStatus({
    required this.requestId,
    required this.transportUsed,
    required this.state,
    required this.attempts,
    required this.roundTripTimeMs,
    this.deliveredAt,
    this.errorReason,
  });

  final String requestId;
  final String transportUsed;
  final DeliveryState state;
  final int attempts;
  final int roundTripTimeMs;
  final DateTime? deliveredAt;
  final String? errorReason;

  DeliveryStatus copyWith({
    String? requestId,
    String? transportUsed,
    DeliveryState? state,
    int? attempts,
    int? roundTripTimeMs,
    DateTime? deliveredAt,
    String? errorReason,
  }) {
    return DeliveryStatus(
      requestId: requestId ?? this.requestId,
      transportUsed: transportUsed ?? this.transportUsed,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      roundTripTimeMs: roundTripTimeMs ?? this.roundTripTimeMs,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      errorReason: errorReason ?? this.errorReason,
    );
  }

  @override
  List<Object?> get props => [
        requestId,
        transportUsed,
        state,
        attempts,
        roundTripTimeMs,
        deliveredAt,
        errorReason,
      ];
}
