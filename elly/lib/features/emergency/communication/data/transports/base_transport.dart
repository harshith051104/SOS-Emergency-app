/// base_transport.dart
///
/// Abstract base interface for all supported communication transports.

library;

import '../../domain/entities/communication_request.dart';
import '../../domain/entities/delivery_status.dart';

abstract class BaseTransport {
  String get transportType;
  bool get isAvailable;

  Future<DeliveryStatus> send(CommunicationRequest request);
}
