/// intent_detection_service.dart
///
/// Application service layer managing timeouts, error classification, empty transcript handling,
/// and Intent telemetry tracking.

library;

import 'dart:async';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_recognition_result.dart';
import 'package:elly/features/emergency/intent_detection/domain/interfaces/i_intent_detector.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent_result.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/intent_error.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/intent_telemetry.dart';

class IntentDetectionService {
  IntentDetectionService({
    required IntentDetector detector,
    int timeoutMs = 1000,
  })  : _detector = detector,
        _timeoutMs = timeoutMs;

  final IntentDetector _detector;
  final int _timeoutMs;
  IntentTelemetry _telemetry = const IntentTelemetry();

  IntentTelemetry get telemetry => _telemetry;

  Future<EmergencyIntentResult> processTranscript(SpeechRecognitionResult transcript) async {
    final text = transcript.text.trim();

    if (text.isEmpty) {
      return EmergencyIntentResult(
        intent: EmergencyIntent.unknown,
        confidence: 0.0,
        processingTimeMs: 0,
        language: transcript.language,
        sessionId: transcript.timestamp.millisecondsSinceEpoch.toString(),
        processingMethod: IntentProcessingMethod.ruleBased,
        detectorVersion: '1.0.0',
        timestamp: DateTime.now(),
      );
    }

    try {
      final result = await _detector
          .analyze(transcript)
          .timeout(Duration(milliseconds: _timeoutMs), onTimeout: () {
        _telemetry = _telemetry.copyWith(timeoutCount: _telemetry.timeoutCount + 1);
        throw IntentError(
          category: IntentErrorCategory.timeout,
          message: 'Intent detection timed out after ${_timeoutMs}ms.',
          timestamp: DateTime.now(),
        );
      });

      _updateTelemetryOnSuccess(result, text.length);
      return result;
    } catch (e) {
      if (e is! IntentError) {
        _updateTelemetryOnFailure();
      }
      rethrow;
    }
  }

  void _updateTelemetryOnSuccess(EmergencyIntentResult result, int textLength) {
    final updatedCounts = Map<EmergencyIntent, int>.from(_telemetry.classificationCounts);
    updatedCounts[result.intent] = (updatedCounts[result.intent] ?? 0) + 1;

    final updatedLangs = Map<String, int>.from(_telemetry.languageDistribution);
    updatedLangs[result.language] = (updatedLangs[result.language] ?? 0) + 1;

    final totalRuns = updatedCounts.values.reduce((a, b) => a + b);

    final avgLatency = ((_telemetry.averageLatencyMs * (totalRuns - 1)) + result.processingTimeMs) ~/ totalRuns;
    final avgConfidence = ((_telemetry.averageConfidence * (totalRuns - 1)) + result.confidence) / totalRuns;
    final avgLength = ((_telemetry.averageTranscriptLength * (totalRuns - 1)) + textLength) ~/ totalRuns;

    _telemetry = _telemetry.copyWith(
      classificationCounts: updatedCounts,
      languageDistribution: updatedLangs,
      averageLatencyMs: avgLatency,
      averageConfidence: avgConfidence,
      averageTranscriptLength: avgLength,
      unknownClassificationCount: updatedCounts[EmergencyIntent.unknown] ?? 0,
    );
  }

  void _updateTelemetryOnFailure() {
    _telemetry = _telemetry.copyWith(failureCount: _telemetry.failureCount + 1);
  }

  void dispose() {
    _detector.dispose();
  }
}
