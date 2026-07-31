/// confirmation_telemetry.dart
///
/// Telemetry metrics for tracking Confirmation Engine performance.

library;

import 'package:flutter/foundation.dart';

@immutable
class ConfirmationTelemetry {
  const ConfirmationTelemetry({
    this.confirmationCount = 0,
    this.timeoutCount = 0,
    this.cancellationCount = 0,
    this.interruptedCount = 0,
    this.averageResponseTimeMs = 0.0,
    this.failureCount = 0,
  });

  final int confirmationCount;
  final int timeoutCount;
  final int cancellationCount;
  final int interruptedCount;
  final double averageResponseTimeMs;
  final int failureCount;

  double get confirmationRate =>
      (confirmationCount + timeoutCount + cancellationCount + interruptedCount) > 0
          ? (confirmationCount / (confirmationCount + timeoutCount + cancellationCount + interruptedCount)) * 100.0
          : 0.0;

  ConfirmationTelemetry recordOutcome({
    required bool isConfirmed,
    required bool isTimeout,
    required bool isCancelled,
    required bool isInterrupted,
    required double responseTimeMs,
  }) {
    final nextCount = confirmationCount + (isConfirmed ? 1 : 0);
    final nextTimeout = timeoutCount + (isTimeout ? 1 : 0);
    final nextCancel = cancellationCount + (isCancelled ? 1 : 0);
    final nextInterrupt = interruptedCount + (isInterrupted ? 1 : 0);
    final total = nextCount + nextTimeout + nextCancel + nextInterrupt;

    final nextAvgResponseTime = ((averageResponseTimeMs * (total - 1)) + responseTimeMs) / (total > 0 ? total : 1);

    return ConfirmationTelemetry(
      confirmationCount: nextCount,
      timeoutCount: nextTimeout,
      cancellationCount: nextCancel,
      interruptedCount: nextInterrupt,
      averageResponseTimeMs: nextAvgResponseTime,
      failureCount: failureCount,
    );
  }

  ConfirmationTelemetry recordFailure() {
    return ConfirmationTelemetry(
      confirmationCount: confirmationCount,
      timeoutCount: timeoutCount,
      cancellationCount: cancellationCount,
      interruptedCount: interruptedCount,
      averageResponseTimeMs: averageResponseTimeMs,
      failureCount: failureCount + 1,
    );
  }
}
