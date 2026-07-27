/// get_monitoring_status_usecase.dart
///
/// Use case to access current monitoring status and telemetry metrics.

library;

import '../entities/monitoring_state.dart';
import '../entities/monitoring_metrics.dart';
import '../repositories/i_monitoring_repository.dart';

class GetMonitoringStatusUseCase {
  const GetMonitoringStatusUseCase(this._repository);

  final IMonitoringRepository _repository;

  MonitoringEngineState get currentState => _repository.currentState;
  MonitoringMetrics get currentMetrics => _repository.currentMetrics;
  Stream<MonitoringEngineState> get stateStream => _repository.stateStream;
}
