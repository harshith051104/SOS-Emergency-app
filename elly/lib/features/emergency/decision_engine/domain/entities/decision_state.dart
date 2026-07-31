/// decision_state.dart
///
/// Presentation state model for the Multi-Signal Decision Engine module.

library;

import 'package:flutter/foundation.dart';
import 'emergency_decision_result.dart';
import 'decision_telemetry.dart';
import 'decision_error.dart';

enum DecisionStatus {
  idle,
  evaluating,
  completed,
  failed,
}

@immutable
class DecisionState {
  const DecisionState({
    this.status = DecisionStatus.idle,
    this.activeSessionId,
    this.lastResult,
    this.telemetry = const DecisionTelemetry(),
    this.evidenceTimeline = const [],
    this.errorCategory,
    this.errorMessage,
  });

  final DecisionStatus status;
  final String? activeSessionId;
  final EmergencyDecisionResult? lastResult;
  final DecisionTelemetry telemetry;
  final List<String> evidenceTimeline;
  final DecisionErrorCategory? errorCategory;
  final String? errorMessage;

  DecisionState copyWith({
    DecisionStatus? status,
    String? activeSessionId,
    EmergencyDecisionResult? lastResult,
    DecisionTelemetry? telemetry,
    List<String>? evidenceTimeline,
    DecisionErrorCategory? errorCategory,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DecisionState(
      status: status ?? this.status,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      lastResult: lastResult ?? this.lastResult,
      telemetry: telemetry ?? this.telemetry,
      evidenceTimeline: evidenceTimeline ?? this.evidenceTimeline,
      errorCategory: clearError ? null : (errorCategory ?? this.errorCategory),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
