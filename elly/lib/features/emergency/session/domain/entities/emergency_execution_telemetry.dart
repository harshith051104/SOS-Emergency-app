/// emergency_execution_telemetry.dart
///
/// Performance and metrics tracking for Phase 8 Emergency Session execution.

library;

import 'package:flutter/foundation.dart';

@immutable
class EmergencyExecutionTelemetry {
  const EmergencyExecutionTelemetry({
    this.sessionsStarted = 0,
    this.sessionsCompleted = 0,
    this.sessionsCancelled = 0,
    this.averageExecutionTimeMs = 0.0,
    this.successfulActionsCount = 0,
    this.failedActionsCount = 0,
  });

  final int sessionsStarted;
  final int sessionsCompleted;
  final int sessionsCancelled;
  final double averageExecutionTimeMs;
  final int successfulActionsCount;
  final int failedActionsCount;

  EmergencyExecutionTelemetry recordSessionComplete({
    required bool isCompleted,
    required bool isCancelled,
    required double executionDurationMs,
    required int successActions,
    required int failActions,
  }) {
    final nextStarted = sessionsStarted + 1;
    final nextCompleted = sessionsCompleted + (isCompleted ? 1 : 0);
    final nextCancelled = sessionsCancelled + (isCancelled ? 1 : 0);
    final nextAvgTime = ((averageExecutionTimeMs * sessionsStarted) + executionDurationMs) / nextStarted;

    return EmergencyExecutionTelemetry(
      sessionsStarted: nextStarted,
      sessionsCompleted: nextCompleted,
      sessionsCancelled: nextCancelled,
      averageExecutionTimeMs: nextAvgTime,
      successfulActionsCount: successfulActionsCount + successActions,
      failedActionsCount: failedActionsCount + failActions,
    );
  }
}
