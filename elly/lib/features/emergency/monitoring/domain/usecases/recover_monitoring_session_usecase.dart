/// recover_monitoring_session_usecase.dart
///
/// Use case to check for and resume an interrupted active session on app restart.

library;

import '../entities/recovery_info.dart';
import '../repositories/i_monitoring_repository.dart';

class RecoverMonitoringSessionUseCase {
  const RecoverMonitoringSessionUseCase(this._repository);

  final IMonitoringRepository _repository;

  Future<RecoveryInfo> execute() async {
    return await _repository.recoverActiveSession();
  }
}
