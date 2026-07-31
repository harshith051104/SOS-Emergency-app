/// speech_recognition_result.dart
///
/// Immutable domain model representing the result of an STT transcription.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_config.dart';

@immutable
class SpeechRecognitionResult {
  const SpeechRecognitionResult({
    required this.text,
    required this.confidence,
    required this.durationMs,
    required this.language,
    required this.inferenceTimeMs,
    required this.engine,
    required this.timestamp,
  });

  final String text;
  final double confidence;
  final int durationMs;
  final String language;
  final int inferenceTimeMs;
  final SpeechEngine engine;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'text': text,
        'confidence': confidence,
        'durationMs': durationMs,
        'language': language,
        'inferenceTimeMs': inferenceTimeMs,
        'engine': engine.name,
        'timestamp': timestamp.toIso8601String(),
      };
}
