/// delivery_tracker_service_test.dart
///
/// Unit tests for DeliveryTrackerService.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/communication/domain/entities/delivery_status.dart';
import 'package:elly/features/emergency/communication/data/services/delivery_tracker_service.dart';

void main() {
  group('DeliveryTrackerService', () {
    late DeliveryTrackerService tracker;

    setUp(() {
      tracker = DeliveryTrackerService();
    });

    tearDown(() async {
      await tracker.dispose();
    });

    test('should record and retrieve delivery receipt status', () {
      final status = DeliveryStatus(
        requestId: 'req_100',
        transportUsed: 'internet',
        state: DeliveryState.acknowledged,
        attempts: 1,
        roundTripTimeMs: 45,
        deliveredAt: DateTime.now(),
      );

      tracker.recordStatus(status);
      final retrieved = tracker.getStatus('req_100');

      expect(retrieved, equals(status));
      expect(retrieved?.state, equals(DeliveryState.acknowledged));
    });
  });
}
