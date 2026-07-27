/// track_delivery_status_usecase.dart
///
/// Use case retrieving delivery tracking receipts.

library;

import '../entities/delivery_status.dart';
import '../repositories/i_delivery_tracker_repository.dart';

class TrackDeliveryStatusUseCase {
  const TrackDeliveryStatusUseCase(this._repository);

  final IDeliveryTrackerRepository _repository;

  Future<DeliveryStatus?> execute(String requestId) async {
    return await _repository.getStatus(requestId);
  }

  Stream<DeliveryStatus> get stream => _repository.deliveryStream;
}
