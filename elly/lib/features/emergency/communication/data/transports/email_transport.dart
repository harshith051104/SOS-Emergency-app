/// email_transport.dart
///
/// Multi-sensor report email dispatch transport.

library;

import 'dart:async';
import '../../domain/entities/communication_request.dart';
import '../../domain/entities/delivery_status.dart';
import 'base_transport.dart';

class EmailTransport implements BaseTransport {
  EmailTransport();

  @override
  String get transportType => 'email';

  @override
  bool get isAvailable => true;

  @override
  Future<DeliveryStatus> send(CommunicationRequest request) async {
    final start = DateTime.now();
    await Future.delayed(const Duration(milliseconds: 250));

    return DeliveryStatus(
      requestId: request.requestId,
      transportUsed: transportType,
      state: DeliveryState.delivered,
      attempts: 1,
      roundTripTimeMs: DateTime.now().difference(start).inMilliseconds,
      deliveredAt: DateTime.now(),
    );
  }
}
