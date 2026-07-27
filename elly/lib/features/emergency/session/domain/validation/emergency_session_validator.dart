/// emergency_session_validator.dart
///
/// Pure domain validator enforcing state machine transitions and session integrity rules.

library;

import 'package:elly/features/emergency/session/domain/entities/emergency_session.dart';
import 'package:elly/features/emergency/session/domain/entities/session_state.dart';

class SessionValidationResult {
  const SessionValidationResult._(this.isValid, this.reason);

  factory SessionValidationResult.valid() => const SessionValidationResult._(true, null);
  factory SessionValidationResult.invalid(String reason) => SessionValidationResult._(false, reason);

  final bool isValid;
  final String? reason;
}

class EmergencySessionValidator {
  static const Set<String> requiredEngines = {
    'Health Passport Engine',
    'Telemetry Engine',
    'SOS Circle Engine',
    'Communication Engine',
  };

  /// Validates transition from currentSession state to targetState.
  static SessionValidationResult validateTransition(EmergencySession currentSession, SessionState targetState) {
    final current = currentSession.state;

    if (current == targetState) {
      return SessionValidationResult.invalid('Session is already in $targetState state.');
    }

    switch (current) {
      case SessionState.idle:
        if (targetState != SessionState.preparing && targetState != SessionState.starting) {
          return SessionValidationResult.invalid('Idle session can only transition to preparing or starting.');
        }

      case SessionState.preparing:
        if (targetState != SessionState.starting && targetState != SessionState.failed) {
          return SessionValidationResult.invalid('Preparing session can only transition to starting or failed.');
        }

      case SessionState.starting:
        if (targetState != SessionState.active && targetState != SessionState.recovering && targetState != SessionState.failed) {
          return SessionValidationResult.invalid('Starting session can transition to active, recovering, or failed.');
        }

      case SessionState.active:
        if (targetState != SessionState.paused && targetState != SessionState.ending && targetState != SessionState.recovering && targetState != SessionState.failed) {
          return SessionValidationResult.invalid('Active session can transition to paused, ending, recovering, or failed.');
        }

      case SessionState.paused:
        if (targetState != SessionState.active && targetState != SessionState.ending) {
          return SessionValidationResult.invalid('Paused session can transition to active or ending.');
        }

      case SessionState.recovering:
        if (targetState != SessionState.active && targetState != SessionState.failed && targetState != SessionState.ending) {
          return SessionValidationResult.invalid('Recovering session can transition to active, ending, or failed.');
        }

      case SessionState.ending:
        if (targetState != SessionState.completed && targetState != SessionState.failed) {
          return SessionValidationResult.invalid('Ending session can transition to completed or failed.');
        }

      case SessionState.completed:
      case SessionState.failed:
        if (targetState != SessionState.idle) {
          return SessionValidationResult.invalid('Terminated session must be reset to idle before restarting.');
        }
    }

    return SessionValidationResult.valid();
  }
}
