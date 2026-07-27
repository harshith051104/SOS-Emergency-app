/// monitoring_event_bus_test.dart
///
/// Unit tests for MonitoringEventBus pub-sub mechanism.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/monitoring_event.dart';
import 'package:elly/features/emergency/monitoring/domain/entities/emergency_severity.dart';
import 'package:elly/features/emergency/monitoring/data/services/monitoring_event_bus.dart';

void main() {
  group('MonitoringEventBus', () {
    late MonitoringEventBus bus;

    setUp(() {
      bus = MonitoringEventBus();
    });

    tearDown(() async {
      await bus.dispose();
    });

    test('should publish and receive filtered event streams', () async {
      final severityEvents = <SeverityChangedEvent>[];
      final subscription = bus.on<SeverityChangedEvent>().listen(severityEvents.add);

      const sev = EmergencySeverity(
        level: EmergencySeverityLevel.critical,
        score: 90,
        contributingFactors: ['Critical Battery'],
      );

      bus.publish(const SeverityChangedEvent(sev));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(severityEvents.length, equals(1));
      expect(severityEvents.first.severity.level, equals(EmergencySeverityLevel.critical));

      await subscription.cancel();
    });
  });
}
