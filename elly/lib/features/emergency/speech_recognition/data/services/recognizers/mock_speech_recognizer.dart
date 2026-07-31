/// mock_speech_recognizer.dart
///
/// Mock implementation of [SpeechRecognizer] for unit tests and fallback platforms.

library;

import 'dart:async';
import 'package:elly/features/emergency/speech_recognition/domain/interfaces/i_speech_recognizer.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_recognition_result.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_config.dart';

class MockSpeechRecognizer implements SpeechRecognizer {
  MockSpeechRecognizer({this.mockText = 'Help! Emergency assistance required!'});

  final String mockText;
  bool _isCancelled = false;

  @override
  Future<SpeechRecognitionResult> transcribe(SpeechSession session) async {
    _isCancelled = false;
    final timestamp = DateTime.now();

    if (session.audioBuffer.pcmData.isEmpty) {
      return SpeechRecognitionResult(
        text: '',
        confidence: 0.0,
        durationMs: 0,
        language: 'en',
        inferenceTimeMs: 0,
        engine: SpeechEngine.mock,
        timestamp: timestamp,
      );
    }

    if (_isCancelled) {
      return SpeechRecognitionResult(
        text: '[CANCELLED]',
        confidence: 0.0,
        durationMs: session.durationMs,
        language: 'en',
        inferenceTimeMs: 1,
        engine: SpeechEngine.mock,
        timestamp: timestamp,
      );
    }

    return SpeechRecognitionResult(
      text: mockText,
      confidence: 0.95,
      durationMs: session.durationMs,
      language: 'en',
      inferenceTimeMs: 12,
      engine: SpeechEngine.mock,
      timestamp: timestamp,
    );
  }

  @override
  Future<void> cancelCurrentRecognition() async {
    _isCancelled = true;
  }

  @override
  void dispose() {}
}
