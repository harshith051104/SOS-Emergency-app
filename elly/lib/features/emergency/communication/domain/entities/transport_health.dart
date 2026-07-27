/// transport_health.dart
///
/// Health state entity for individual communication transport channels.

library;

import 'package:equatable/equatable.dart';

enum TransportHealthStatus {
  healthy,
  degraded,
  busy,
  unavailable,
}

class TransportHealth extends Equatable {
  const TransportHealth({
    required this.transportType,
    required this.status,
    required this.consecutiveFailures,
    required this.lastCheck,
  });

  final String transportType;
  final TransportHealthStatus status;
  final int consecutiveFailures;
  final DateTime lastCheck;

  bool get isOperational => status == TransportHealthStatus.healthy || status == TransportHealthStatus.degraded;

  @override
  List<Object?> get props => [
        transportType,
        status,
        consecutiveFailures,
        lastCheck,
      ];
}
