/// sync_status.dart
///
/// Domain entity representing background synchronization state & metrics.

library;

import 'package:equatable/equatable.dart';

class SyncStatus extends Equatable {
  const SyncStatus({
    required this.isSynchronizing,
    required this.pendingCount,
    required this.syncedCount,
    required this.failedCount,
    this.lastSyncTime,
    required this.currentBackoffDelayMs,
    required this.windowModeActive,
  });

  final bool isSynchronizing;
  final int pendingCount;
  final int syncedCount;
  final int failedCount;
  final DateTime? lastSyncTime;
  final int currentBackoffDelayMs;
  final bool windowModeActive;

  factory SyncStatus.idle() {
    return const SyncStatus(
      isSynchronizing: false,
      pendingCount: 0,
      syncedCount: 0,
      failedCount: 0,
      currentBackoffDelayMs: 1000,
      windowModeActive: false,
    );
  }

  SyncStatus copyWith({
    bool? isSynchronizing,
    int? pendingCount,
    int? syncedCount,
    int? failedCount,
    DateTime? lastSyncTime,
    int? currentBackoffDelayMs,
    bool? windowModeActive,
  }) {
    return SyncStatus(
      isSynchronizing: isSynchronizing ?? this.isSynchronizing,
      pendingCount: pendingCount ?? this.pendingCount,
      syncedCount: syncedCount ?? this.syncedCount,
      failedCount: failedCount ?? this.failedCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      currentBackoffDelayMs: currentBackoffDelayMs ?? this.currentBackoffDelayMs,
      windowModeActive: windowModeActive ?? this.windowModeActive,
    );
  }

  @override
  List<Object?> get props => [
        isSynchronizing,
        pendingCount,
        syncedCount,
        failedCount,
        lastSyncTime,
        currentBackoffDelayMs,
        windowModeActive,
      ];
}
