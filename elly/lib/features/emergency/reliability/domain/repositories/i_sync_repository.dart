/// i_sync_repository.dart
///
/// Interface for synchronization engine execution and metrics.

library;

import '../entities/sync_status.dart';
import '../entities/offline_session_summary.dart';

abstract class ISyncRepository {
  Stream<SyncStatus> get syncStatusStream;
  SyncStatus get currentSyncStatus;

  Future<OfflineSessionSummary?> triggerSynchronization({
    required String sessionId,
    bool burstWindowMode = false,
  });
}
