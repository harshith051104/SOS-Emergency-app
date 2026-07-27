/// sensor_priority.dart
///
/// Domain entity defining sensor priority tiers for resource shedding during battery saver/emergencies.

library;

import 'package:equatable/equatable.dart';
import 'sensor_health.dart';

enum SensorPriorityLevel {
  critical,  // GPS, Battery, Connectivity
  important, // Motion
  optional,  // Health, Bluetooth
}

class SensorPriorityAssignment extends Equatable {
  const SensorPriorityAssignment({
    required this.sensorType,
    required this.priorityLevel,
  });

  final SensorType sensorType;
  final SensorPriorityLevel priorityLevel;

  @override
  List<Object?> get props => [sensorType, priorityLevel];
}
