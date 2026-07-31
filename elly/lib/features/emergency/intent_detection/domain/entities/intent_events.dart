/// intent_events.dart
///
/// Strongly typed, schema-versioned PlatformEvent extensions for Emergency Intent Detection.

library;

import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent.dart';

class IntentDetectionStartedPlatformEvent extends PlatformEvent {
  IntentDetectionStartedPlatformEvent({
    required String sessionId,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_intent_start_${timestamp.millisecondsSinceEpoch}',
          eventName: 'IntentDetectionStarted',
          payload: {
            'sessionId': sessionId,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class IntentDetectionCompletedPlatformEvent extends PlatformEvent {
  IntentDetectionCompletedPlatformEvent({
    required String sessionId,
    required IntentProcessingMethod processingMethod,
    required String detectorVersion,
    required int processingTimeMs,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_intent_comp_${timestamp.millisecondsSinceEpoch}',
          eventName: 'IntentDetectionCompleted',
          payload: {
            'sessionId': sessionId,
            'processingMethod': processingMethod.name,
            'detectorVersion': detectorVersion,
            'processingTimeMs': processingTimeMs,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class IntentDetectedPlatformEvent extends PlatformEvent {
  IntentDetectedPlatformEvent({
    required String sessionId,
    required EmergencyIntent intent,
    required double confidence,
    required String language,
    required IntentProcessingMethod processingMethod,
    required String detectorVersion,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_intent_det_${timestamp.millisecondsSinceEpoch}',
          eventName: 'IntentDetected',
          payload: {
            'sessionId': sessionId,
            'intent': intent.name,
            'confidence': confidence,
            'language': language,
            'processingMethod': processingMethod.name,
            'detectorVersion': detectorVersion,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}
