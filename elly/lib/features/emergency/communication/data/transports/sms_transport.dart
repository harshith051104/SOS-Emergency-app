/// sms_transport.dart
///
/// Compact SMS text formatter for emergency contacts and fallback gateway dispatch.

library;

import 'dart:async';
import '../../domain/entities/communication_request.dart';
import '../../domain/entities/delivery_status.dart';
import 'base_transport.dart';

class SmsTransport implements BaseTransport {
  SmsTransport({this.forceFailure = false});

  final bool forceFailure;

  @override
  String get transportType => 'sms';

  @override
  bool get isAvailable => true;

  @override
  Future<DeliveryStatus> send(CommunicationRequest request) async {
    final start = DateTime.now();
    await Future.delayed(const Duration(milliseconds: 150));

    if (forceFailure) {
      return DeliveryStatus(
        requestId: request.requestId,
        transportUsed: transportType,
        state: DeliveryState.failed,
        attempts: 1,
        roundTripTimeMs: DateTime.now().difference(start).inMilliseconds,
        errorReason: 'Cellular network SMS gateway timeout',
      );
    }

    return DeliveryStatus(
      requestId: request.requestId,
      transportUsed: transportType,
      state: DeliveryState.delivered,
      attempts: 1,
      roundTripTimeMs: DateTime.now().difference(start).inMilliseconds,
      deliveredAt: DateTime.now(),
    );
  }

  String formatCompactSms(String rawPayload) {
    return '[ELLY SOS EMERGENCY ALERT] Need urgent assistance! Target: Active Session';
  }
}
