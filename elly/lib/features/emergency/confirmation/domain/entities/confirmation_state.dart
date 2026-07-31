/// confirmation_state.dart
///
/// Presentation state model for the Confirmation Engine module.

library;

import 'package:flutter/foundation.dart';
import 'confirmation_result.dart';
import 'confirmation_strategy.dart';
import 'confirmation_telemetry.dart';
import 'confirmation_error.dart';
import 'session_lifecycle_state.dart';
import 'interruption_reason.dart';

enum ConfirmationStatus {
  idle,
  waiting,
  confirmed,
  cancelled,
  timedOut,
  interrupted,
  completed,
  failed,
}

@immutable
class ConfirmationState {
  const ConfirmationState({
    this.status = ConfirmationStatus.idle,
    this.sessionLifecycleState = SessionLifecycleState.created,
    this.activeStrategy = const NormalStrategy(),
    this.activeSessionId,
    this.lastResult,
    this.remainingSeconds = 0,
    this.interruptionReason = InterruptionReason.none,
    this.telemetry = const ConfirmationTelemetry(),
    this.errorCategory,
    this.errorMessage,
  });

  final ConfirmationStatus status;
  final SessionLifecycleState sessionLifecycleState;
  final ConfirmationStrategy activeStrategy;
  final String? activeSessionId;
  final ConfirmationResult? lastResult;
  final int remainingSeconds;
  final InterruptionReason interruptionReason;
  final ConfirmationTelemetry telemetry;
  final ConfirmationErrorCategory? errorCategory;
  final String? errorMessage;

  ConfirmationState copyWith({
    ConfirmationStatus? status,
    SessionLifecycleState? sessionLifecycleState,
    ConfirmationStrategy? activeStrategy,
    String? activeSessionId,
    ConfirmationResult? lastResult,
    int? remainingSeconds,
    InterruptionReason? interruptionReason,
    ConfirmationTelemetry? telemetry,
    ConfirmationErrorCategory? errorCategory,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConfirmationState(
      status: status ?? this.status,
      sessionLifecycleState: sessionLifecycleState ?? this.sessionLifecycleState,
      activeStrategy: activeStrategy ?? this.activeStrategy,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      lastResult: lastResult ?? this.lastResult,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      interruptionReason: interruptionReason ?? this.interruptionReason,
      telemetry: telemetry ?? this.telemetry,
      errorCategory: clearError ? null : (errorCategory ?? this.errorCategory),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
