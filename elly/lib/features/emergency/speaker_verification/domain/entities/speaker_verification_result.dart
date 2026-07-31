/// speaker_verification_result.dart
///
/// Immutable domain model representing the output of a speaker verification run.

library;

import 'package:flutter/foundation.dart';

enum SpeakerVerificationMethod {
  embedding,
  mock,
}

@immutable
class SpeakerVerificationResult {
  const SpeakerVerificationResult({
    required this.sessionId,
    required this.match,
    required this.confidence,
    required this.profileId,
    required this.processingTimeMs,
    required this.embeddingVersion,
    required this.processingMethod,
    required this.timestamp,
  });

  final String sessionId;
  final bool match;
  final double confidence;
  final String profileId;
  final int processingTimeMs;
  final String embeddingVersion;
  final SpeakerVerificationMethod processingMethod;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'match': match,
        'confidence': confidence,
        'profileId': profileId,
        'processingTimeMs': processingTimeMs,
        'embeddingVersion': embeddingVersion,
        'processingMethod': processingMethod.name,
        'timestamp': timestamp.toIso8601String(),
      };
}
