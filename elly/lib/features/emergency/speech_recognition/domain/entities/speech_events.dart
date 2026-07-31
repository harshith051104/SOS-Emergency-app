/// speech_events.dart
///
/// Strongly typed, schema-versioned PlatformEvent extensions for Speech Recognition.

library;

import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_config.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_error.dart';

class TranscriptionStartedPlatformEvent extends PlatformEvent {
  TranscriptionStartedPlatformEvent({
    required String sessionId,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_stt_start_${timestamp.millisecondsSinceEpoch}',
          eventName: 'TranscriptionStarted',
          payload: {
            'sessionId': sessionId,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class TranscriptionCompletedPlatformEvent extends PlatformEvent {
  TranscriptionCompletedPlatformEvent({
    required String sessionId,
    required SpeechEngine engine,
    required int inferenceTimeMs,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_stt_comp_${timestamp.millisecondsSinceEpoch}',
          eventName: 'TranscriptionCompleted',
          payload: {
            'sessionId': sessionId,
            'engine': engine.name,
            'inferenceTimeMs': inferenceTimeMs,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class SpeechRecognizedPlatformEvent extends PlatformEvent {
  SpeechRecognizedPlatformEvent({
    required String sessionId,
    required String transcript,
    required double confidence,
    required String language,
    required SpeechEngine engine,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_speech_rec_${timestamp.millisecondsSinceEpoch}',
          eventName: 'SpeechRecognized',
          payload: {
            'sessionId': sessionId,
            'transcript': transcript,
            'confidence': confidence,
            'language': language,
            'engine': engine.name,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class SpeechRecognitionFailedPlatformEvent extends PlatformEvent {
  SpeechRecognitionFailedPlatformEvent({
    required String sessionId,
    required SpeechErrorCategory errorCategory,
    required String errorMessage,
    required SpeechEngine engine,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_stt_fail_${timestamp.millisecondsSinceEpoch}',
          eventName: 'SpeechRecognitionFailed',
          payload: {
            'sessionId': sessionId,
            'errorCategory': errorCategory.name,
            'errorMessage': errorMessage,
            'engine': engine.name,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}
