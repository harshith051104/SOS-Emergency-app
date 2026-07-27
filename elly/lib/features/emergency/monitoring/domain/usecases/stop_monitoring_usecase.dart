/// stop_monitoring_usecase.dart
///
/// Use case to gracefully finalize and stop emergency monitoring.

library;

import '../repositories/i_monitoring_repository.dart';

class StopMonitoringUseCase {
  const StopMonitoringUseCase(this._repository);

  final IMonitoringRepository _repository;

  Future<void> execute() async {
    await _repository.stopMonitoring();
  }
}
