/// sensor_health_monitor_test.dart
///
/// Unit tests for SensorHealthMonitor lifecycle transitions.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/sensor_health.dart';
import 'package:elly/features/emergency/monitoring/data/services/sensor_health_monitor.dart';

void main() {
  group('SensorHealthMonitor', () {
    late SensorHealthMonitor monitor;

    setUp(() {
      monitor = SensorHealthMonitor();
    });

    test('should transition sensor status healthy -> degraded -> unavailable on failures', () {
      final h1 = monitor.recordFailure(SensorType.location, 'Timeout 1');
      expect(h1.status, equals(SensorHealthStatus.degraded));
      expect(h1.consecutiveFailures, equals(1));

      final h2 = monitor.recordFailure(SensorType.location, 'Timeout 2');
      expect(h2.status, equals(SensorHealthStatus.degraded));
      expect(h2.consecutiveFailures, equals(2));

      final h3 = monitor.recordFailure(SensorType.location, 'Timeout 3');
      expect(h3.status, equals(SensorHealthStatus.unavailable));
      expect(h3.consecutiveFailures, equals(3));
    });

    test('should recover sensor state on success', () {
      monitor.recordFailure(SensorType.location, 'Timeout 1');
      monitor.recordFailure(SensorType.location, 'Timeout 2');
      monitor.recordFailure(SensorType.location, 'Timeout 3');

      final recovered = monitor.recordSuccess(SensorType.location);
      expect(recovered.status, equals(SensorHealthStatus.recovered));
      expect(recovered.consecutiveFailures, equals(0));
    });
  });
}
