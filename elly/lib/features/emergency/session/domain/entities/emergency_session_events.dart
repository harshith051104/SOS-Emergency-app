/// emergency_session_events.dart
///
/// Schema-versioned (v1) PlatformEvent definitions for Phase 8 Emergency Session Activation.

library;

import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'emergency_session_result.dart';

class EmergencySessionStartedPlatformEvent extends PlatformEvent {
  EmergencySessionStartedPlatformEvent({
    required String sessionId,
    required String triggerOutcome,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_sess_start_${timestamp.millisecondsSinceEpoch}',
          eventName: 'EmergencySessionStarted',
          payload: {
            'sessionId': sessionId,
            'triggerOutcome': triggerOutcome,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class EmergencyActionStartedPlatformEvent extends PlatformEvent {
  EmergencyActionStartedPlatformEvent({
    required String sessionId,
    required String actionId,
    required String actionName,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_act_start_${timestamp.millisecondsSinceEpoch}',
          eventName: 'EmergencyActionStarted',
          payload: {
            'sessionId': sessionId,
            'actionId': actionId,
            'actionName': actionName,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class EmergencyActionCompletedPlatformEvent extends PlatformEvent {
  EmergencyActionCompletedPlatformEvent({
    required String sessionId,
    required String actionId,
    required bool success,
    required int executionTimeMs,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_act_comp_${timestamp.millisecondsSinceEpoch}',
          eventName: 'EmergencyActionCompleted',
          payload: {
            'sessionId': sessionId,
            'actionId': actionId,
            'success': success,
            'executionTimeMs': executionTimeMs,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class EmergencyAcknowledgementPlatformEvent extends PlatformEvent {
  EmergencyAcknowledgementPlatformEvent({
    required String sessionId,
    required String status,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_ack_${timestamp.millisecondsSinceEpoch}',
          eventName: 'EmergencyAcknowledgement',
          payload: {
            'sessionId': sessionId,
            'status': status,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class EmergencySessionCompletedPlatformEvent extends PlatformEvent {
  EmergencySessionCompletedPlatformEvent({
    required EmergencySessionResult result,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_sess_comp_${timestamp.millisecondsSinceEpoch}',
          eventName: 'EmergencySessionCompleted',
          payload: {
            'sessionId': result.sessionId,
            'sessionState': result.sessionState.name,
            'executedActions': result.executedActions,
            'successfulActions': result.successfulActions,
            'failedActions': result.failedActions,
            'acknowledgementStatus': result.acknowledgementStatus.name,
            'executionDurationMs': result.executionDurationMs,
            'engineVersion': result.engineVersion,
            'algorithmVersion': result.algorithmVersion,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}
