/// battery_budget_manager.dart
///
/// Service enforcing battery preservation rules by shedding optional and important sensor collectors.

library;

import '../../domain/entities/sensor_health.dart';
import '../../domain/entities/sensor_priority.dart';

class BatteryBudgetPolicy {
  const BatteryBudgetPolicy({
    required this.shouldCollectMotion,
    required this.shouldCollectHealth,
    required this.targetGpsIntervalMultiplier,
  });

  final bool shouldCollectMotion;
  final bool shouldCollectHealth;
  final double targetGpsIntervalMultiplier;
}

class BatteryBudgetManager {
  const BatteryBudgetManager();

  static const Map<SensorType, SensorPriorityLevel> priorityMap = {
    SensorType.location: SensorPriorityLevel.critical,
    SensorType.device: SensorPriorityLevel.critical,
    SensorType.connectivity: SensorPriorityLevel.critical,
    SensorType.application: SensorPriorityLevel.critical,
    SensorType.motion: SensorPriorityLevel.important,
    SensorType.health: SensorPriorityLevel.optional,
  };

  /// Evaluates battery level and yields collection policy.
  BatteryBudgetPolicy evaluatePolicy({
    required int batteryPercent,
    required bool isCharging,
  }) {
    if (isCharging || batteryPercent > 20) {
      return const BatteryBudgetPolicy(
        shouldCollectMotion: true,
        shouldCollectHealth: true,
        targetGpsIntervalMultiplier: 1.0,
      );
    } else if (batteryPercent > 10) {
      // Shed optional sensors (Health)
      return const BatteryBudgetPolicy(
        shouldCollectMotion: true,
        shouldCollectHealth: false,
        targetGpsIntervalMultiplier: 1.5,
      );
    } else {
      // Critical battery (< 10%): Shed Optional & Important (Health, Motion) to save max battery
      return const BatteryBudgetPolicy(
        shouldCollectMotion: false,
        shouldCollectHealth: false,
        targetGpsIntervalMultiplier: 2.0,
      );
    }
  }

  bool isSensorAllowed({
    required SensorType sensorType,
    required int batteryPercent,
    required bool isCharging,
  }) {
    final policy = evaluatePolicy(batteryPercent: batteryPercent, isCharging: isCharging);
    final priority = priorityMap[sensorType] ?? SensorPriorityLevel.critical;

    if (priority == SensorPriorityLevel.critical) return true;
    if (priority == SensorPriorityLevel.important) return policy.shouldCollectMotion;
    if (priority == SensorPriorityLevel.optional) return policy.shouldCollectHealth;
    return true;
  }
}
