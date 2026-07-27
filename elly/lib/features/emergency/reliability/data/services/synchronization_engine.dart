/// synchronization_engine.dart
///
/// Background synchronization engine with exponential backoff and burst window mode.

library;

import 'dart:async';
import '../../domain/entities/sync_status.dart';
import '../../domain/entities/offline_session_summary.dart';
import '../../domain/entities/emergency_queue_item.dart';
import 'emergency_queue_manager.dart';

class SynchronizationEngine {
  SynchronizationEngine({
    required EmergencyQueueManager queueManager,
  })  : _queueManager = queueManager,
        _syncStatusController = StreamController<SyncStatus>.broadcast();

  final EmergencyQueueManager _queueManager;
  final StreamController<SyncStatus> _syncStatusController;

  SyncStatus _currentSyncStatus = SyncStatus.idle();
  int _backoffDelayMs = 1000;

  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  SyncStatus get currentSyncStatus => _currentSyncStatus;

  Future<OfflineSessionSummary?> synchronizeSession({
    required String sessionId,
    bool burstWindowMode = false,
    DateTime? offlineStartTime,
  }) async {
    if (_currentSyncStatus.isSynchronizing) return null;

    final startSync = DateTime.now();
    _updateSyncStatus(_currentSyncStatus.copyWith(
      isSynchronizing: true,
      windowModeActive: burstWindowMode,
    ));

    final scheduledItems = await _queueManager.getScheduledQueue(sessionId);
    if (scheduledItems.isEmpty) {
      _updateSyncStatus(_currentSyncStatus.copyWith(
        isSynchronizing: false,
        pendingCount: 0,
        currentBackoffDelayMs: 1000,
      ));
      return null;
    }

    int synced = 0;
    int failed = 0;

    for (final item in scheduledItems) {
      try {
        // Simulate payload transmission & delivery ack
        final success = await _transmitItem(item);

        if (success) {
          await _queueManager.markCompleted(sessionId, item.id);
          synced++;
          _backoffDelayMs = 1000; // Reset backoff on success
        } else {
          await _queueManager.markFailed(sessionId, item.id);
          failed++;
          _applyExponentialBackoff();
        }
      } catch (_) {
        await _queueManager.markFailed(sessionId, item.id);
        failed++;
        _applyExponentialBackoff();
      }
    }

    final endSync = DateTime.now();
    final remaining = await _queueManager.getScheduledQueue(sessionId);

    _updateSyncStatus(SyncStatus(
      isSynchronizing: false,
      pendingCount: remaining.length,
      syncedCount: _currentSyncStatus.syncedCount + synced,
      failedCount: _currentSyncStatus.failedCount + failed,
      lastSyncTime: endSync,
      currentBackoffDelayMs: _backoffDelayMs,
      windowModeActive: false,
    ));

    final offlineDuration = offlineStartTime != null ? startSync.difference(offlineStartTime) : Duration.zero;

    return OfflineSessionSummary(
      sessionId: sessionId,
      offlineDuration: offlineDuration,
      packetsGeneratedOffline: scheduledItems.length,
      packetsUploaded: synced,
      syncDuration: endSync.difference(startSync),
      reconnectedAt: endSync,
    );
  }

  Future<bool> _transmitItem(EmergencyQueueItem item) async {
    await Future.delayed(const Duration(milliseconds: 30));
    return true; // Transmitted successfully
  }

  void _applyExponentialBackoff() {
    _backoffDelayMs = (_backoffDelayMs * 2).clamp(1000, 30000);
  }

  void _updateSyncStatus(SyncStatus status) {
    _currentSyncStatus = status;
    if (!_syncStatusController.isClosed) {
      Future<void>(() {
        if (!_syncStatusController.isClosed) _syncStatusController.add(_currentSyncStatus);
      });
    }
  }

  Future<void> dispose() async {
    await _syncStatusController.close();
  }
}
