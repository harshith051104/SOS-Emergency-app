/// emergency_session_state.dart
///
/// Presentation state model for Phase 8 Emergency Session execution.

library;

import 'package:flutter/foundation.dart';
import 'emergency_session_result.dart';
import 'emergency_execution_telemetry.dart';
import 'emergency_execution_error.dart';

enum EmergencySessionStatus {
  idle,
  starting,
  executing,
  waitingAcknowledgement,
  completed,
  failed,
  cancelled,
}

@immutable
class EmergencySessionState {
  const EmergencySessionState({
    this.status = EmergencySessionStatus.idle,
    this.activeSessionId,
    this.lastResult,
    this.executionTimeline = const [],
    this.telemetry = const EmergencyExecutionTelemetry(),
    this.errorCategory,
    this.errorMessage,
  });

  final EmergencySessionStatus status;
  final String? activeSessionId;
  final EmergencySessionResult? lastResult;
  final List<String> executionTimeline;
  final EmergencyExecutionTelemetry telemetry;
  final EmergencyExecutionErrorCategory? errorCategory;
  final String? errorMessage;

  EmergencySessionState copyWith({
    EmergencySessionStatus? status,
    String? activeSessionId,
    EmergencySessionResult? lastResult,
    List<String>? executionTimeline,
    EmergencyExecutionTelemetry? telemetry,
    EmergencyExecutionErrorCategory? errorCategory,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EmergencySessionState(
      status: status ?? this.status,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      lastResult: lastResult ?? this.lastResult,
      executionTimeline: executionTimeline ?? this.executionTimeline,
      telemetry: telemetry ?? this.telemetry,
      errorCategory: clearError ? null : (errorCategory ?? this.errorCategory),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
