/// update_monitoring_config_usecase.dart
///
/// Use case to dynamically adjust monitoring configuration intervals or settings.

library;

import '../entities/monitoring_config.dart';
import '../repositories/i_monitoring_repository.dart';

class UpdateMonitoringConfigUseCase {
  const UpdateMonitoringConfigUseCase(this._repository);

  final IMonitoringRepository _repository;

  void execute(MonitoringConfig config) {
    _repository.updateConfig(config);
  }
}
