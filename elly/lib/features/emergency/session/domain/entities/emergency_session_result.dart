/// emergency_session_result.dart
///
/// Immutable domain model containing the evaluated execution output of an Emergency Session.

library;

import 'package:flutter/foundation.dart';
import 'acknowledgement_status.dart';
import 'action_result.dart';

enum SessionState {
  created,
  executing,
  waitingAcknowledgement,
  completed,
  failed,
  cancelled,
}

@immutable
class EmergencySessionResult {
  const EmergencySessionResult({
    required this.sessionId,
    required this.sessionState,
    this.executedActions = const [],
    this.successfulActions = const [],
    this.failedActions = const [],
    this.pendingActions = const [],
    this.actionResults = const [],
    required this.acknowledgementStatus,
    required this.executionDurationMs,
    this.engineVersion = 'v1.0.0-rules',
    this.algorithmVersion = 'v1.0.0-orchestrated',
    required this.timestamp,
  });

  final String sessionId;
  final SessionState sessionState;
  final List<String> executedActions;
  final List<String> successfulActions;
  final List<String> failedActions;
  final List<String> pendingActions;
  final List<ActionResult> actionResults;
  final AcknowledgementStatus acknowledgementStatus;
  final int executionDurationMs;
  final String engineVersion;
  final String algorithmVersion;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'sessionState': sessionState.name,
        'executedActions': executedActions,
        'successfulActions': successfulActions,
        'failedActions': failedActions,
        'pendingActions': pendingActions,
        'acknowledgementStatus': acknowledgementStatus.name,
        'executionDurationMs': executionDurationMs,
        'engineVersion': engineVersion,
        'algorithmVersion': algorithmVersion,
        'timestamp': timestamp.toIso8601String(),
      };
}
