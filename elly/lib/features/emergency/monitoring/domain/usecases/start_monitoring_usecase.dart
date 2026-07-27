/// start_monitoring_usecase.dart
///
/// Use case to start the Emergency Monitoring Engine.

library;

import '../entities/monitoring_config.dart';
import '../repositories/i_monitoring_repository.dart';

class StartMonitoringUseCase {
  const StartMonitoringUseCase(this._repository);

  final IMonitoringRepository _repository;

  Future<void> execute({
    required String sessionId,
    required String triggerType,
    MonitoringConfig? config,
  }) async {
    await _repository.startMonitoring(
      sessionId: sessionId,
      triggerType: triggerType,
      config: config,
    );
  }
}
