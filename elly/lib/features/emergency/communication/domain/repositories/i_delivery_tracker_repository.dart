/// i_delivery_tracker_repository.dart
///
/// Interface for tracking end-to-end receipt auditing.

library;

import '../entities/delivery_status.dart';

abstract class IDeliveryTrackerRepository {
  Stream<DeliveryStatus> get deliveryStream;

  Future<void> recordDeliveryStatus(DeliveryStatus status);
  Future<DeliveryStatus?> getStatus(String requestId);
  Future<List<DeliveryStatus>> getAllStatuses();
}
