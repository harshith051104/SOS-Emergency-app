/// monitoring_state.dart
///
/// Domain entity representing the engine status and active execution context.

library;

import 'package:equatable/equatable.dart';
import 'monitoring_config.dart';

enum MonitoringStatus {
  idle,
  initializing,
  active,
  paused,
  stopping,
  recovering,
}

class MonitoringEngineState extends Equatable {
  const MonitoringEngineState({
    required this.status,
    this.sessionId,
    this.startedAt,
    required this.activeConfig,
    this.currentPacketNumber = 0,
    this.lastError,
  });

  final MonitoringStatus status;
  final String? sessionId;
  final DateTime? startedAt;
  final MonitoringConfig activeConfig;
  final int currentPacketNumber;
  final String? lastError;

  bool get isRunning =>
      status == MonitoringStatus.active || status == MonitoringStatus.recovering;

  MonitoringEngineState copyWith({
    MonitoringStatus? status,
    String? sessionId,
    DateTime? startedAt,
    MonitoringConfig? activeConfig,
    int? currentPacketNumber,
    String? lastError,
  }) {
    return MonitoringEngineState(
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      activeConfig: activeConfig ?? this.activeConfig,
      currentPacketNumber: currentPacketNumber ?? this.currentPacketNumber,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        sessionId,
        startedAt,
        activeConfig,
        currentPacketNumber,
        lastError,
      ];
}
