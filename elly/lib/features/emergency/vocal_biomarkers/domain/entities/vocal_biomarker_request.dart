/// vocal_biomarker_request.dart
///
/// Immutable domain model for a vocal biomarker analysis request.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';

@immutable
class VocalBiomarkerRequest {
  const VocalBiomarkerRequest({
    required this.sessionId,
    required this.audioBuffer,
    this.sampleRate = 16000,
    required this.timestamp,
  });

  final String sessionId;
  final AudioBuffer audioBuffer;
  final int sampleRate;
  final DateTime timestamp;

  int get durationMs => audioBuffer.durationMs;
}
