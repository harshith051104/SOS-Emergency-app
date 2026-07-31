/// speaker_verification_events.dart
///
/// Strongly typed, schema-versioned PlatformEvent extensions for Speaker Verification.

library;

import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_result.dart';

class SpeakerVerificationStartedPlatformEvent extends PlatformEvent {
  SpeakerVerificationStartedPlatformEvent({
    required String sessionId,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_spk_start_${timestamp.millisecondsSinceEpoch}',
          eventName: 'SpeakerVerificationStarted',
          payload: {
            'sessionId': sessionId,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class SpeakerVerificationCompletedPlatformEvent extends PlatformEvent {
  SpeakerVerificationCompletedPlatformEvent({
    required String sessionId,
    required SpeakerVerificationMethod processingMethod,
    required String embeddingVersion,
    required int processingTimeMs,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_spk_comp_${timestamp.millisecondsSinceEpoch}',
          eventName: 'SpeakerVerificationCompleted',
          payload: {
            'sessionId': sessionId,
            'processingMethod': processingMethod.name,
            'embeddingVersion': embeddingVersion,
            'processingTimeMs': processingTimeMs,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class SpeakerVerifiedPlatformEvent extends PlatformEvent {
  SpeakerVerifiedPlatformEvent({
    required String sessionId,
    required bool match,
    required double confidence,
    required String profileId,
    required SpeakerVerificationMethod processingMethod,
    required String embeddingVersion,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_spk_ver_${timestamp.millisecondsSinceEpoch}',
          eventName: 'SpeakerVerified',
          payload: {
            'sessionId': sessionId,
            'match': match,
            'confidence': confidence,
            'profileId': profileId,
            'processingMethod': processingMethod.name,
            'embeddingVersion': embeddingVersion,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}
