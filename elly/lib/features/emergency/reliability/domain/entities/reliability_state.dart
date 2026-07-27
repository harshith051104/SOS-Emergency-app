/// reliability_state.dart
///
/// Deterministic Reliability State Machine status domain entity.

library;

import 'package:equatable/equatable.dart';

enum ReliabilityStatus {
  idle,
  preparing,
  onlineMonitoring,
  offlineMonitoring,
  queueing,
  synchronizing,
  recovered,
  completed,
  failed,
}

class ReliabilityState extends Equatable {
  const ReliabilityState({
    required this.status,
    this.sessionId,
    this.startedAt,
    this.lastTransitionTime,
    this.lastError,
  });

  final ReliabilityStatus status;
  final String? sessionId;
  final DateTime? startedAt;
  final DateTime? lastTransitionTime;
  final String? lastError;

  bool get isOfflineMode => status == ReliabilityStatus.offlineMonitoring;
  bool get isSyncing => status == ReliabilityStatus.synchronizing;

  ReliabilityState copyWith({
    ReliabilityStatus? status,
    String? sessionId,
    DateTime? startedAt,
    DateTime? lastTransitionTime,
    String? lastError,
  }) {
    return ReliabilityState(
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      lastTransitionTime: lastTransitionTime ?? this.lastTransitionTime,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        sessionId,
        startedAt,
        lastTransitionTime,
        lastError,
      ];
}
