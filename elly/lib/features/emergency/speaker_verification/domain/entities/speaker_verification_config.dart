/// speaker_verification_config.dart
///
/// Configuration model for Speaker Verification thresholds and embedding settings.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_result.dart';

@immutable
class SpeakerVerificationConfig {
  const SpeakerVerificationConfig({
    this.verifierType = SpeakerVerificationMethod.embedding,
    this.similarityThreshold = 0.75,
    this.minimumAudioDurationMs = 1000,
    this.maxLatencyMs = 100,
    this.embeddingVersion = 'v1.0',
  });

  final SpeakerVerificationMethod verifierType;
  final double similarityThreshold;
  final int minimumAudioDurationMs;
  final int maxLatencyMs;
  final String embeddingVersion;

  SpeakerVerificationConfig copyWith({
    SpeakerVerificationMethod? verifierType,
    double? similarityThreshold,
    int? minimumAudioDurationMs,
    int? maxLatencyMs,
    String? embeddingVersion,
  }) {
    return SpeakerVerificationConfig(
      verifierType: verifierType ?? this.verifierType,
      similarityThreshold: similarityThreshold ?? this.similarityThreshold,
      minimumAudioDurationMs: minimumAudioDurationMs ?? this.minimumAudioDurationMs,
      maxLatencyMs: maxLatencyMs ?? this.maxLatencyMs,
      embeddingVersion: embeddingVersion ?? this.embeddingVersion,
    );
  }

  Map<String, dynamic> toJson() => {
        'verifierType': verifierType.name,
        'similarityThreshold': similarityThreshold,
        'minimumAudioDurationMs': minimumAudioDurationMs,
        'maxLatencyMs': maxLatencyMs,
        'embeddingVersion': embeddingVersion,
      };
}
