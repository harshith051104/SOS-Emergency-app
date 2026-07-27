/// delivery_tracker_service.dart
///
/// Service auditing end-to-end delivery receipts and status histories.

library;

import 'dart:async';
import '../../domain/entities/delivery_status.dart';

class DeliveryTrackerService {
  DeliveryTrackerService()
      : _streamController = StreamController<DeliveryStatus>.broadcast();

  final StreamController<DeliveryStatus> _streamController;
  final Map<String, DeliveryStatus> _registry = {};

  Stream<DeliveryStatus> get deliveryStream => _streamController.stream;

  void recordStatus(DeliveryStatus status) {
    _registry[status.requestId] = status;
    if (!_streamController.isClosed) {
      Future<void>(() {
        if (!_streamController.isClosed) _streamController.add(status);
      });
    }
  }

  DeliveryStatus? getStatus(String requestId) => _registry[requestId];

  List<DeliveryStatus> getAllStatuses() => _registry.values.toList().reversed.toList();

  Future<void> dispose() async {
    await _streamController.close();
  }
}
