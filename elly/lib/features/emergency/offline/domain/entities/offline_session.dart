/// offline_session.dart
///
/// Immutable aggregate root model representing offline emergency mode state.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/offline/domain/entities/network_state.dart';
import 'package:elly/features/emergency/offline/domain/entities/synchronization_state.dart';
import 'package:elly/features/emergency/offline/domain/entities/pending_operation.dart';

@immutable
class OfflineSession {
  const OfflineSession({
    required this.sessionId,
    required this.startedAt,
    this.lastSync,
    this.synchronizationState = SynchronizationState.idle,
    this.pendingOperations = const [],
    this.retryCount = 0,
    this.networkState = NetworkState.online,
  });

  final String sessionId;
  final DateTime startedAt;
  final DateTime? lastSync;
  final SynchronizationState synchronizationState;
  final List<PendingOperation> pendingOperations;
  final int retryCount;
  final NetworkState networkState;

  bool get isOffline => networkState == NetworkState.offline;

  OfflineSession copyWith({
    String? sessionId,
    DateTime? startedAt,
    DateTime? lastSync,
    SynchronizationState? synchronizationState,
    List<PendingOperation>? pendingOperations,
    int? retryCount,
    NetworkState? networkState,
  }) {
    return OfflineSession(
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      lastSync: lastSync ?? this.lastSync,
      synchronizationState: synchronizationState ?? this.synchronizationState,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      retryCount: retryCount ?? this.retryCount,
      networkState: networkState ?? this.networkState,
    );
  }
}
