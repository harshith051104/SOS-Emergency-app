/// decision_events.dart
///
/// Schema-versioned (v1) PlatformEvent definitions for the Multi-Signal Decision Engine.

library;

import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'emergency_decision_result.dart';

class DecisionStartedPlatformEvent extends PlatformEvent {
  DecisionStartedPlatformEvent({
    required String sessionId,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_dec_start_${timestamp.millisecondsSinceEpoch}',
          eventName: 'DecisionStarted',
          payload: {
            'sessionId': sessionId,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class DecisionCompletedPlatformEvent extends PlatformEvent {
  DecisionCompletedPlatformEvent({
    required String sessionId,
    required String recommendation,
    required double confidence,
    required int processingTimeMs,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_dec_comp_${timestamp.millisecondsSinceEpoch}',
          eventName: 'DecisionCompleted',
          payload: {
            'sessionId': sessionId,
            'recommendation': recommendation,
            'confidence': confidence,
            'processingTimeMs': processingTimeMs,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class EmergencyDecisionPlatformEvent extends PlatformEvent {
  EmergencyDecisionPlatformEvent({
    required EmergencyDecisionResult result,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_dec_decision_${timestamp.millisecondsSinceEpoch}',
          eventName: 'EmergencyDecision',
          payload: {
            'sessionId': result.sessionId,
            'emergencyConfidence': result.emergencyConfidence,
            'recommendation': result.recommendation.name,
            'evidenceUsed': result.evidenceUsed,
            'evidenceIgnored': result.evidenceIgnored,
            'missingEvidence': result.missingEvidence,
            'expiredEvidence': result.expiredEvidence,
            'decisionReasons': result.decisionReasons,
            'ruleTrace': result.ruleTrace,
            'processingTimeMs': result.processingTimeMs,
            'engineVersion': result.engineVersion,
            'algorithmVersion': result.algorithmVersion,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}
