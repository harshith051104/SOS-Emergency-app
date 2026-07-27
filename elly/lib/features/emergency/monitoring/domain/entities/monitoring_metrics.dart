/// monitoring_metrics.dart
///
/// Operational performance and reliability metrics.

library;

import 'package:equatable/equatable.dart';

class MonitoringMetrics extends Equatable {
  const MonitoringMetrics({
    required this.packetsGenerated,
    required this.packetsStored,
    required this.currentIntervalMs,
    required this.averageCollectionTimeMs,
    required this.lastGpsAccuracy,
    required this.batteryConsumptionPercent,
    this.lastLocationUpdateTime,
    required this.monitoringUptime,
    this.lastSuccessfulCollectionTime,
    required this.packetGenerationRatePerMin,
  });

  final int packetsGenerated;
  final int packetsStored;
  final int currentIntervalMs;
  final double averageCollectionTimeMs;
  final String lastGpsAccuracy;
  final int batteryConsumptionPercent;
  final DateTime? lastLocationUpdateTime;
  final Duration monitoringUptime;
  final DateTime? lastSuccessfulCollectionTime;
  final double packetGenerationRatePerMin;

  factory MonitoringMetrics.zero() {
    return const MonitoringMetrics(
      packetsGenerated: 0,
      packetsStored: 0,
      currentIntervalMs: 10000,
      averageCollectionTimeMs: 0.0,
      lastGpsAccuracy: 'Unknown',
      batteryConsumptionPercent: 0,
      monitoringUptime: Duration.zero,
      packetGenerationRatePerMin: 0.0,
    );
  }

  MonitoringMetrics copyWith({
    int? packetsGenerated,
    int? packetsStored,
    int? currentIntervalMs,
    double? averageCollectionTimeMs,
    String? lastGpsAccuracy,
    int? batteryConsumptionPercent,
    DateTime? lastLocationUpdateTime,
    Duration? monitoringUptime,
    DateTime? lastSuccessfulCollectionTime,
    double? packetGenerationRatePerMin,
  }) {
    return MonitoringMetrics(
      packetsGenerated: packetsGenerated ?? this.packetsGenerated,
      packetsStored: packetsStored ?? this.packetsStored,
      currentIntervalMs: currentIntervalMs ?? this.currentIntervalMs,
      averageCollectionTimeMs:
          averageCollectionTimeMs ?? this.averageCollectionTimeMs,
      lastGpsAccuracy: lastGpsAccuracy ?? this.lastGpsAccuracy,
      batteryConsumptionPercent:
          batteryConsumptionPercent ?? this.batteryConsumptionPercent,
      lastLocationUpdateTime:
          lastLocationUpdateTime ?? this.lastLocationUpdateTime,
      monitoringUptime: monitoringUptime ?? this.monitoringUptime,
      lastSuccessfulCollectionTime:
          lastSuccessfulCollectionTime ?? this.lastSuccessfulCollectionTime,
      packetGenerationRatePerMin:
          packetGenerationRatePerMin ?? this.packetGenerationRatePerMin,
    );
  }

  @override
  List<Object?> get props => [
        packetsGenerated,
        packetsStored,
        currentIntervalMs,
        averageCollectionTimeMs,
        lastGpsAccuracy,
        batteryConsumptionPercent,
        lastLocationUpdateTime,
        monitoringUptime,
        lastSuccessfulCollectionTime,
        packetGenerationRatePerMin,
      ];
}
