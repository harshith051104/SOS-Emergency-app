/// speaker_verification_request.dart
///
/// Request model for Speaker Verification input containing audio buffer and session context.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';

@immutable
class SpeakerVerificationRequest {
  const SpeakerVerificationRequest({
    required this.sessionId,
    required this.audioBuffer,
    this.sampleRate = 16000,
    required this.timestamp,
  });

  final String sessionId;
  final AudioBuffer audioBuffer;
  final int sampleRate;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'durationMs': audioBuffer.durationMs,
        'sampleRate': sampleRate,
        'timestamp': timestamp.toIso8601String(),
      };
}
