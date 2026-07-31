/// i_voice_activity_detector.dart
///
/// Abstraction interface for Voice Activity Detection engine.
/// Allows swapping underlying Silero VAD / ONNX runtime detectors
/// without changing higher level application code or Riverpod providers.

library;

import 'package:flutter/foundation.dart';

@immutable
class AudioFrame {
  const AudioFrame({
    required this.pcmData,
    this.sampleRate = 16000,
    this.channels = 1,
  });

  final Uint8List pcmData;
  final int sampleRate;
  final int channels;
}

@immutable
class VadResult {
  const VadResult({
    required this.isSpeech,
    required this.speechProbability,
    required this.timestamp,
  });

  final bool isSpeech;
  final double speechProbability;
  final DateTime timestamp;
}

abstract class VoiceActivityDetector {
  Future<VadResult> analyze(AudioFrame frame);
  void dispose();
}
