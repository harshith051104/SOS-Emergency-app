/// mock_speaker_verifier.dart
///
/// Mock implementation of [SpeakerVerifier] for unit testing and fallback platforms.

library;

import 'dart:async';
import 'package:elly/features/emergency/speaker_verification/domain/interfaces/i_speaker_verifier.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_request.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_result.dart';

class MockSpeakerVerifier implements SpeakerVerifier {
  MockSpeakerVerifier({
    this.forcedMatch = true,
    this.forcedConfidence = 0.94,
    this.forcedProfileId = 'owner_primary',
  });

  final bool forcedMatch;
  final double forcedConfidence;
  final String forcedProfileId;

  @override
  Future<SpeakerVerificationResult> verify(SpeakerVerificationRequest request) async {
    final timestamp = DateTime.now();

    if (request.audioBuffer.pcmData.isEmpty) {
      return SpeakerVerificationResult(
        sessionId: request.sessionId,
        match: false,
        confidence: 0.0,
        profileId: forcedProfileId,
        processingTimeMs: 1,
        embeddingVersion: 'mock-1.0',
        processingMethod: SpeakerVerificationMethod.mock,
        timestamp: timestamp,
      );
    }

    return SpeakerVerificationResult(
      sessionId: request.sessionId,
      match: forcedMatch,
      confidence: forcedConfidence,
      profileId: forcedProfileId,
      processingTimeMs: 5,
      embeddingVersion: 'mock-1.0',
      processingMethod: SpeakerVerificationMethod.mock,
      timestamp: timestamp,
    );
  }

  @override
  void dispose() {}
}
