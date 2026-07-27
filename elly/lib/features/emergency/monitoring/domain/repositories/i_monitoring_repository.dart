/// i_monitoring_repository.dart
///
/// Interface for orchestrating the emergency monitoring engine loop.

library;

import '../entities/monitoring_config.dart';
import '../entities/monitoring_state.dart';
import '../entities/monitoring_metrics.dart';
import '../entities/packet_record.dart';
import '../entities/recovery_info.dart';
import '../entities/monitoring_event.dart';

abstract class IMonitoringRepository {
  /// Stream of monitoring engine state transitions.
  Stream<MonitoringEngineState> get stateStream;

  /// Stream of generated packets.
  Stream<PacketRecord> get packetStream;

  /// Stream of system monitoring events (pub-sub bus).
  Stream<MonitoringEvent> get eventStream;

  /// Current monitoring state.
  MonitoringEngineState get currentState;

  /// Current metrics.
  MonitoringMetrics get currentMetrics;

  /// Starts continuous monitoring for the given session ID.
  Future<void> startMonitoring({
    required String sessionId,
    required String triggerType,
    MonitoringConfig? config,
  });

  /// Stops monitoring gracefully and finalizes session.
  Future<void> stopMonitoring();

  /// Updates adaptive monitoring configuration on the fly.
  void updateConfig(MonitoringConfig newConfig);

  /// Triggers an immediate manually forced telemetry cycle.
  Future<PacketRecord?> forceTelemetryCycle({required String reasonCode});

  /// Attempts to auto-recover an active interrupted monitoring session after app restart.
  Future<RecoveryInfo> recoverActiveSession();
}
