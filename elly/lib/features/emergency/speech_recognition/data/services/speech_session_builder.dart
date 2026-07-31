/// speech_session_builder.dart
///
/// Builds immutable [SpeechSession] objects with typed [SpeechSessionMetadata].

library;

import 'dart:typed_data';

import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';

class SpeechSessionBuilder {
  static SpeechSession buildSession({
    required Uint8List pcmData,
    required DateTime startedAt,
    required DateTime endedAt,
    double vadConfidence = 0.85,
    double? estimatedNoiseLevel,
    int frameCount = 0,
    bool wasCancelled = false,
    int sampleRate = 16000,
  }) {
    final buffer = AudioBuffer(
      pcmData: pcmData,
      sampleRate: sampleRate,
    );

    final durationMs = endedAt.difference(startedAt).inMilliseconds;

    final metadata = SpeechSessionMetadata(
      vadConfidence: vadConfidence,
      estimatedNoiseLevel: estimatedNoiseLevel,
      frameCount: frameCount,
      wasCancelled: wasCancelled,
    );

    return SpeechSession(
      sessionId: 'sess_stt_${startedAt.millisecondsSinceEpoch}',
      audioBuffer: buffer,
      startedAt: startedAt,
      endedAt: endedAt,
      durationMs: durationMs > 0 ? durationMs : buffer.durationMs,
      metadata: metadata,
    );
  }
}
