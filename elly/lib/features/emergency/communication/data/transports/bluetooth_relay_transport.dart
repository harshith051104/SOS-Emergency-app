/// bluetooth_relay_transport.dart
///
/// Peer-to-peer Bluetooth discovery & relay simulation transport.

library;

import 'dart:async';
import '../../domain/entities/communication_request.dart';
import '../../domain/entities/delivery_status.dart';
import 'base_transport.dart';

class BluetoothRelayTransport implements BaseTransport {
  BluetoothRelayTransport({this.isAvailable = false});

  @override
  final bool isAvailable;

  @override
  String get transportType => 'bluetooth';

  @override
  Future<DeliveryStatus> send(CommunicationRequest request) async {
    final start = DateTime.now();
    await Future.delayed(const Duration(milliseconds: 300));

    return DeliveryStatus(
      requestId: request.requestId,
      transportUsed: transportType,
      state: isAvailable ? DeliveryState.delivered : DeliveryState.failed,
      attempts: 1,
      roundTripTimeMs: DateTime.now().difference(start).inMilliseconds,
      errorReason: isAvailable ? null : 'No nearby Bluetooth relay device found',
    );
  }
}
