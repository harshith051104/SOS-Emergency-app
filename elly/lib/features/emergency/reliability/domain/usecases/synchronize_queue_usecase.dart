/// synchronize_queue_usecase.dart
///
/// Use case triggering queue synchronization.

library;

import '../entities/offline_session_summary.dart';
import '../repositories/i_sync_repository.dart';

class SynchronizeQueueUseCase {
  const SynchronizeQueueUseCase(this._repository);

  final ISyncRepository _repository;

  Future<OfflineSessionSummary?> execute({
    required String sessionId,
    bool burstWindowMode = false,
  }) async {
    return await _repository.triggerSynchronization(
      sessionId: sessionId,
      burstWindowMode: burstWindowMode,
    );
  }
}
