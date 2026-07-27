/// mesh_transport.dart
///
/// Multi-hop phone mesh network relay simulation transport.

library;

import 'dart:async';
import '../../domain/entities/communication_request.dart';
import '../../domain/entities/delivery_status.dart';
import 'base_transport.dart';

class MeshTransport implements BaseTransport {
  MeshTransport({this.isAvailable = false});

  @override
  final bool isAvailable;

  @override
  String get transportType => 'mesh';

  @override
  Future<DeliveryStatus> send(CommunicationRequest request) async {
    final start = DateTime.now();
    await Future.delayed(const Duration(milliseconds: 350));

    return DeliveryStatus(
      requestId: request.requestId,
      transportUsed: transportType,
      state: isAvailable ? DeliveryState.delivered : DeliveryState.failed,
      attempts: 1,
      roundTripTimeMs: DateTime.now().difference(start).inMilliseconds,
      errorReason: isAvailable ? null : 'No mesh route path to internet gateway available',
    );
  }
}
