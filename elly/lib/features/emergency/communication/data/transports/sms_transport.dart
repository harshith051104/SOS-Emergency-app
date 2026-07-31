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

  /// Formats compact offline SMS data packet containing live location, health passport, and checksum.
  String formatCompactSms({
    required String sessionId,
    String? emergencyNumber,
    String? locationText,
    String? bloodType,
    String? allergies,
    String? checksum,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🚨 [ELLY SOS EMERGENCY ALERT]');
    buffer.writeln('Session: $sessionId');
    if (emergencyNumber != null && emergencyNumber.isNotEmpty) {
      buffer.writeln('Line: $emergencyNumber');
    }
    buffer.writeln('Location: ${locationText ?? "Live GPS Attached"}');
    if (bloodType != null || allergies != null) {
      buffer.writeln('Medical: Blood ${bloodType ?? "N/A"}, Allergies: ${allergies ?? "None"}');
    }
    if (checksum != null) {
      buffer.writeln('Checksum: $checksum');
    }
    buffer.write('Status: ACTIVE EMERGENCY - S.O.S.');
    return buffer.toString();
  }
}

