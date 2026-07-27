/// sync_repository_impl.dart
///
/// Implementation of ISyncRepository.

library;

import '../../domain/entities/sync_status.dart';
import '../../domain/entities/offline_session_summary.dart';
import '../../domain/repositories/i_sync_repository.dart';
import '../services/synchronization_engine.dart';

class SyncRepositoryImpl implements ISyncRepository {
  SyncRepositoryImpl({
    required SynchronizationEngine syncEngine,
  }) : _syncEngine = syncEngine;

  final SynchronizationEngine _syncEngine;

  @override
  Stream<SyncStatus> get syncStatusStream => _syncEngine.syncStatusStream;

  @override
  SyncStatus get currentSyncStatus => _syncEngine.currentSyncStatus;

  @override
  Future<OfflineSessionSummary?> triggerSynchronization({
    required String sessionId,
    bool burstWindowMode = false,
  }) async {
    return await _syncEngine.synchronizeSession(
      sessionId: sessionId,
      burstWindowMode: burstWindowMode,
    );
  }
}
