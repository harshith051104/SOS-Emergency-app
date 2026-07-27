/// monitoring_config.dart
///
/// Domain entity configuring adaptive intervals, timeouts, and feature flags.

library;

import 'package:equatable/equatable.dart';

class MonitoringConfig extends Equatable {
  const MonitoringConfig({
    this.normalInterval = const Duration(seconds: 10),
    this.criticalInterval = const Duration(seconds: 5),
    this.batterySaverInterval = const Duration(seconds: 20),
    this.stationaryInterval = const Duration(seconds: 20),
    this.fastMotionInterval = const Duration(seconds: 4),
    this.enableHealthCollector = false,
    this.enableMotionCollector = true,
    this.collectorTimeoutBudget = const Duration(milliseconds: 2000),
    this.retentionDays = 30,
  });

  /// Default collection frequency for standard emergencies.
  final Duration normalInterval;

  /// High frequency collection for critical emergencies.
  final Duration criticalInterval;

  /// Reduced frequency when device is in battery saver mode.
  final Duration batterySaverInterval;

  /// Reduced frequency when user has been stationary for extended period.
  final Duration stationaryInterval;

  /// Elevated frequency when fast movement is detected.
  final Duration fastMotionInterval;

  /// Optional flag to gather wearable / health data.
  final bool enableHealthCollector;

  /// Flag to enable motion state detection.
  final bool enableMotionCollector;

  /// Max allowable execution budget for any individual collector.
  final Duration collectorTimeoutBudget;

  /// Number of days to retain completed emergency sessions.
  final int retentionDays;

  MonitoringConfig copyWith({
    Duration? normalInterval,
    Duration? criticalInterval,
    Duration? batterySaverInterval,
    Duration? stationaryInterval,
    Duration? fastMotionInterval,
    bool? enableHealthCollector,
    bool? enableMotionCollector,
    Duration? collectorTimeoutBudget,
    int? retentionDays,
  }) {
    return MonitoringConfig(
      normalInterval: normalInterval ?? this.normalInterval,
      criticalInterval: criticalInterval ?? this.criticalInterval,
      batterySaverInterval: batterySaverInterval ?? this.batterySaverInterval,
      stationaryInterval: stationaryInterval ?? this.stationaryInterval,
      fastMotionInterval: fastMotionInterval ?? this.fastMotionInterval,
      enableHealthCollector:
          enableHealthCollector ?? this.enableHealthCollector,
      enableMotionCollector:
          enableMotionCollector ?? this.enableMotionCollector,
      collectorTimeoutBudget:
          collectorTimeoutBudget ?? this.collectorTimeoutBudget,
      retentionDays: retentionDays ?? this.retentionDays,
    );
  }

  @override
  List<Object?> get props => [
        normalInterval,
        criticalInterval,
        batterySaverInterval,
        stationaryInterval,
        fastMotionInterval,
        enableHealthCollector,
        enableMotionCollector,
        collectorTimeoutBudget,
        retentionDays,
      ];
}
