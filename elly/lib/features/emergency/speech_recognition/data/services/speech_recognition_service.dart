/// speech_recognition_service.dart
///
/// Application service layer managing single-utterance queue policy (max queue len = 1),
/// timeouts, cancellation, error handling, and STT telemetry metrics.

library;

import 'dart:async';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/speech_recognition/domain/interfaces/i_speech_recognizer.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_recognition_result.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_error.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_telemetry.dart';

class SpeechRecognitionService {
  SpeechRecognitionService({
    required SpeechRecognizer recognizer,
    int timeoutSeconds = 30,
  })  : _recognizer = recognizer,
        _timeoutSeconds = timeoutSeconds;

  final SpeechRecognizer _recognizer;
  final int _timeoutSeconds;
  SpeechTelemetry _telemetry = const SpeechTelemetry();
  bool _isProcessing = false;

  SpeechTelemetry get telemetry => _telemetry;

  Future<SpeechRecognitionResult> processSession(SpeechSession session) async {
    // Single-utterance queue policy (Max Queue Len = 1)
    if (_isProcessing) {
      appLogger.info('SpeechRecognitionService: Cancelling in-flight recognition for new session ${session.sessionId}');
      await _recognizer.cancelCurrentRecognition();
      _telemetry = _telemetry.copyWith(cancellationCount: _telemetry.cancellationCount + 1);
    }

    _isProcessing = true;

    if (session.audioBuffer.pcmData.isEmpty) {
      _isProcessing = false;
      _telemetry = _telemetry.copyWith(recognitionsFailed: _telemetry.recognitionsFailed + 1);
      throw SpeechError(
        category: SpeechErrorCategory.invalidAudio,
        message: 'Audio buffer contains zero PCM bytes.',
        timestamp: DateTime.now(),
      );
    }

    try {
      final result = await _recognizer
          .transcribe(session)
          .timeout(Duration(seconds: _timeoutSeconds), onTimeout: () {
        _telemetry = _telemetry.copyWith(timeoutCount: _telemetry.timeoutCount + 1);
        throw SpeechError(
          category: SpeechErrorCategory.timeout,
          message: 'Speech transcription timed out after ${_timeoutSeconds}s.',
          timestamp: DateTime.now(),
        );
      });

      _isProcessing = false;

      if (result.text == '[CANCELLED]') {
        _telemetry = _telemetry.copyWith(cancellationCount: _telemetry.cancellationCount + 1);
        throw SpeechError(
          category: SpeechErrorCategory.cancelled,
          message: 'Transcription cancelled.',
          timestamp: DateTime.now(),
        );
      }

      // Update telemetry
      final completed = _telemetry.recognitionsCompleted + 1;
      final avgInference = ((_telemetry.averageInferenceTimeMs * _telemetry.recognitionsCompleted) + result.inferenceTimeMs) ~/ completed;
      final avgDuration = ((_telemetry.averageUtteranceDurationMs * _telemetry.recognitionsCompleted) + result.durationMs) ~/ completed;

      _telemetry = _telemetry.copyWith(
        recognitionsCompleted: completed,
        averageInferenceTimeMs: avgInference,
        averageUtteranceDurationMs: avgDuration,
        averageConfidence: result.confidence,
      );

      return result;
    } catch (e) {
      _isProcessing = false;
      _telemetry = _telemetry.copyWith(recognitionsFailed: _telemetry.recognitionsFailed + 1);
      rethrow;
    }
  }

  Future<void> cancelActiveRecognition() async {
    if (_isProcessing) {
      await _recognizer.cancelCurrentRecognition();
      _isProcessing = false;
      _telemetry = _telemetry.copyWith(cancellationCount: _telemetry.cancellationCount + 1);
      appLogger.info('SpeechRecognitionService: Active recognition cancelled by user/system request.');
    }
  }

  void dispose() {
    _recognizer.dispose();
  }
}
