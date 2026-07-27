/// delivery_tracker_repository_impl.dart
///
/// Implementation of IDeliveryTrackerRepository.

library;

import '../../domain/entities/delivery_status.dart';
import '../../domain/repositories/i_delivery_tracker_repository.dart';
import '../services/delivery_tracker_service.dart';

class DeliveryTrackerRepositoryImpl implements IDeliveryTrackerRepository {
  DeliveryTrackerRepositoryImpl({
    required DeliveryTrackerService trackerService,
  }) : _trackerService = trackerService;

  final DeliveryTrackerService _trackerService;

  @override
  Stream<DeliveryStatus> get deliveryStream => _trackerService.deliveryStream;

  @override
  Future<void> recordDeliveryStatus(DeliveryStatus status) async {
    _trackerService.recordStatus(status);
  }

  @override
  Future<DeliveryStatus?> getStatus(String requestId) async {
    return _trackerService.getStatus(requestId);
  }

  @override
  Future<List<DeliveryStatus>> getAllStatuses() async {
    return _trackerService.getAllStatuses();
  }
}
