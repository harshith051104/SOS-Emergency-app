/// internet_transport.dart
///
/// HTTPS/REST payload transmission adaptor.
///
/// CURRENT STATUS: Structural stub — the REST backend endpoint is not yet
/// provisioned. This transport records the attempt and returns a pending state
/// rather than faking a success. Once the backend endpoint is deployed, replace
/// the body of [send] with a real http.post() call.
///
/// Do NOT add simulated Future.delayed() here. Either it sends or it doesn't.

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
    // TODO(backend): Replace with real http.post() once REST endpoint is live.
    // Example:
    //   final response = await http.post(
    //     Uri.parse('https://api.elly.app/v1/emergency/dispatch'),
    //     headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    //     body: jsonEncode(request.toJson()),
    //   );
    //   if (response.statusCode == 200) return DeliveryStatus(...acknowledged...);

    if (forceFailure) {
      return DeliveryStatus(
        requestId: request.requestId,
        transportUsed: transportType,
        state: DeliveryState.failed,
        attempts: 1,
        roundTripTimeMs: 0,
        errorReason: 'Backend endpoint not yet provisioned.',
      );
    }

    // Return queued — backend is not deployed yet. Do not fake success.
    return DeliveryStatus(
      requestId: request.requestId,
      transportUsed: transportType,
      state: DeliveryState.queued,
      attempts: 1,
      roundTripTimeMs: 0,
      errorReason: 'REST backend endpoint pending provisioning.',
    );
  }
}
