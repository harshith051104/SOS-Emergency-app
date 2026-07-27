/// internet_transport.dart
///
/// HTTPS/REST payload transmission adaptor.

library;

import 'dart:async';
import '../../domain/entities/communication_request.dart';
import '../../domain/entities/delivery_status.dart';
import 'base_transport.dart';

class InternetTransport implements BaseTransport {
  InternetTransport({this.forceFailure = false});

  final bool forceFailure;

  @override
  String get transportType => 'internet';

  @override
  bool get isAvailable => true;

  @override
  Future<DeliveryStatus> send(CommunicationRequest request) async {
    final start = DateTime.now();
    await Future.delayed(const Duration(milliseconds: 120));

    if (forceFailure) {
      return DeliveryStatus(
        requestId: request.requestId,
        transportUsed: transportType,
        state: DeliveryState.failed,
        attempts: 1,
        roundTripTimeMs: DateTime.now().difference(start).inMilliseconds,
        errorReason: 'HTTP REST endpoint 503 Service Unavailable',
      );
    }

    return DeliveryStatus(
      requestId: request.requestId,
      transportUsed: transportType,
      state: DeliveryState.acknowledged,
      attempts: 1,
      roundTripTimeMs: DateTime.now().difference(start).inMilliseconds,
      deliveredAt: DateTime.now(),
    );
  }
}
