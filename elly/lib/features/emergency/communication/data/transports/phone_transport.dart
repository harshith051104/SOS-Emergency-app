/// phone_transport.dart
///
/// Phone call escalation transport launcher.

library;

import 'dart:async';
import '../../domain/entities/communication_request.dart';
import '../../domain/entities/delivery_status.dart';
import 'base_transport.dart';

class PhoneTransport implements BaseTransport {
  PhoneTransport();

  @override
  String get transportType => 'phone';

  @override
  bool get isAvailable => true;

  @override
  Future<DeliveryStatus> send(CommunicationRequest request) async {
    final start = DateTime.now();
    await Future.delayed(const Duration(milliseconds: 200));

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
