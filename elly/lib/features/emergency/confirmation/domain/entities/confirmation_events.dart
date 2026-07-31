/// confirmation_events.dart
///
/// Schema-versioned (v1) PlatformEvent definitions for the Confirmation Engine.

library;

import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'confirmation_result.dart';

class ConfirmationStartedPlatformEvent extends PlatformEvent {
  ConfirmationStartedPlatformEvent({
    required String sessionId,
    required String strategyName,
    required int timeoutSeconds,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_conf_start_${timestamp.millisecondsSinceEpoch}',
          eventName: 'ConfirmationStarted',
          payload: {
            'sessionId': sessionId,
            'strategyName': strategyName,
            'timeoutSeconds': timeoutSeconds,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class ConfirmationReceivedPlatformEvent extends PlatformEvent {
  ConfirmationReceivedPlatformEvent({
    required String sessionId,
    required String method,
    required String responseText,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_conf_recv_${timestamp.millisecondsSinceEpoch}',
          eventName: 'ConfirmationReceived',
          payload: {
            'sessionId': sessionId,
            'method': method,
            'responseText': responseText,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class ConfirmationTimeoutPlatformEvent extends PlatformEvent {
  ConfirmationTimeoutPlatformEvent({
    required String sessionId,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_conf_timeout_${timestamp.millisecondsSinceEpoch}',
          eventName: 'ConfirmationTimeout',
          payload: {
            'sessionId': sessionId,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class ConfirmationCompletedPlatformEvent extends PlatformEvent {
  ConfirmationCompletedPlatformEvent({
    required ConfirmationResult result,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_conf_comp_${timestamp.millisecondsSinceEpoch}',
          eventName: 'ConfirmationCompleted',
          payload: {
            'sessionId': result.sessionId,
            'confirmationOutcome': result.confirmationOutcome.name,
            'confirmationMethod': result.confirmationMethod.name,
            'responseTimeMs': result.responseTimeMs,
            'userResponse': result.userResponse,
            'engineVersion': result.engineVersion,
            'algorithmVersion': result.algorithmVersion,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}
