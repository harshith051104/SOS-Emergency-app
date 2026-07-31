/// confirmation_result.dart
///
/// Immutable domain model containing the evaluated confirmation result.

library;

import 'package:flutter/foundation.dart';
import 'confirmation_outcome.dart';
import 'confirmation_method.dart';
import 'session_lifecycle_state.dart';
import 'interruption_reason.dart';

@immutable
class ConfirmationResult {
  const ConfirmationResult({
    required this.sessionId,
    required this.confirmationOutcome,
    required this.sessionLifecycleState,
    required this.confirmationMethod,
    required this.responseTimeMs,
    this.userResponse,
    this.interruptionReason = InterruptionReason.none,
    this.engineVersion = 'v1.0.0-rules',
    this.algorithmVersion = 'v1.0.0-strategy',
    required this.timestamp,
  });

  final String sessionId;
  final ConfirmationOutcome confirmationOutcome;
  final SessionLifecycleState sessionLifecycleState;
  final ConfirmationMethod confirmationMethod;
  final int responseTimeMs;
  final String? userResponse;
  final InterruptionReason interruptionReason;
  final String engineVersion;
  final String algorithmVersion;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'confirmationOutcome': confirmationOutcome.name,
        'sessionLifecycleState': sessionLifecycleState.name,
        'confirmationMethod': confirmationMethod.name,
        'responseTimeMs': responseTimeMs,
        'userResponse': userResponse,
        'interruptionReason': interruptionReason.name,
        'engineVersion': engineVersion,
        'algorithmVersion': algorithmVersion,
        'timestamp': timestamp.toIso8601String(),
      };
}
