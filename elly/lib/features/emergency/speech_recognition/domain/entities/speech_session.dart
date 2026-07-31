/// speech_session.dart
///
/// Immutable domain value objects representing an audio buffer and a speech utterance session.

library;

import 'package:flutter/foundation.dart';

@immutable
class AudioBuffer {
  const AudioBuffer({
    required this.pcmData,
    this.sampleRate = 16000,
    this.channels = 1,
  });

  final Uint8List pcmData;
  final int sampleRate;
  final int channels;

  int get durationMs => sampleRate > 0 ? (pcmData.length ~/ (sampleRate * 2 * channels / 1000)) : 0;
}

@immutable
class SpeechSessionMetadata {
  const SpeechSessionMetadata({
    this.vadConfidence = 0.85,
    this.estimatedNoiseLevel,
    this.frameCount = 0,
    this.wasCancelled = false,
  });

  final double vadConfidence;
  final double? estimatedNoiseLevel;
  final int frameCount;
  final bool wasCancelled;

  Map<String, dynamic> toJson() => {
        'vadConfidence': vadConfidence,
        'estimatedNoiseLevel': estimatedNoiseLevel,
        'frameCount': frameCount,
        'wasCancelled': wasCancelled,
      };
}

@immutable
class SpeechSession {
  const SpeechSession({
    required this.sessionId,
    required this.audioBuffer,
    required this.startedAt,
    required this.endedAt,
    required this.durationMs,
    this.metadata = const SpeechSessionMetadata(),
  });

  final String sessionId;
  final AudioBuffer audioBuffer;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMs;
  final SpeechSessionMetadata metadata;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'durationMs': durationMs,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'metadata': metadata.toJson(),
      };
}
