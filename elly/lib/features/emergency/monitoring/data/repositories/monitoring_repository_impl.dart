/// monitoring_repository_impl.dart
///
/// Implementation of IMonitoringRepository wrapping MonitoringEngineService.

library;

import '../../domain/entities/monitoring_config.dart';
import '../../domain/entities/monitoring_state.dart';
import '../../domain/entities/monitoring_metrics.dart';
import '../../domain/entities/packet_record.dart';
import '../../domain/entities/recovery_info.dart';
import '../../domain/entities/monitoring_event.dart';
import '../../domain/repositories/i_monitoring_repository.dart';
import '../services/monitoring_engine_service.dart';

class MonitoringRepositoryImpl implements IMonitoringRepository {
  MonitoringRepositoryImpl(this._engineService);

  final MonitoringEngineService _engineService;

  @override
  Stream<MonitoringEngineState> get stateStream => _engineService.stateStream;

  @override
  Stream<PacketRecord> get packetStream => _engineService.packetStream;

  @override
  Stream<MonitoringEvent> get eventStream => _engineService.eventStream;

  @override
  MonitoringEngineState get currentState => _engineService.currentState;

  @override
  MonitoringMetrics get currentMetrics => _engineService.currentMetrics;

  @override
  Future<void> startMonitoring({
    required String sessionId,
    required String triggerType,
    MonitoringConfig? config,
  }) async {
    await _engineService.startMonitoring(
      sessionId: sessionId,
      triggerType: triggerType,
      config: config,
    );
  }

  @override
  Future<void> stopMonitoring() async {
    await _engineService.stopMonitoring();
  }

  @override
  void updateConfig(MonitoringConfig newConfig) {
    _engineService.updateConfig(newConfig);
  }

  @override
  Future<PacketRecord?> forceTelemetryCycle({required String reasonCode}) async {
    return await _engineService.executeCycleManual(reasonCode: reasonCode);
  }

  @override
  Future<RecoveryInfo> recoverActiveSession() async {
    return await _engineService.recoverActiveSession();
  }
}
