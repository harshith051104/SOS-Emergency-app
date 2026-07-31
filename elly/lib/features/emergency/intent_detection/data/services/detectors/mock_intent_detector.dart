/// mock_intent_detector.dart
///
/// Mock implementation of [IntentDetector] for unit testing and fallback platforms.

library;

import 'dart:async';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_recognition_result.dart';
import 'package:elly/features/emergency/intent_detection/domain/interfaces/i_intent_detector.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent_result.dart';

class MockIntentDetector implements IntentDetector {
  MockIntentDetector({this.forcedIntent, this.forcedConfidence});

  final EmergencyIntent? forcedIntent;
  final double? forcedConfidence;

  @override
  Future<EmergencyIntentResult> analyze(SpeechRecognitionResult transcript) async {
    final timestamp = DateTime.now();
    final text = transcript.text.trim().toLowerCase();

    if (text.isEmpty) {
      return EmergencyIntentResult(
        intent: EmergencyIntent.unknown,
        confidence: 0.0,
        processingTimeMs: 1,
        language: transcript.language,
        sessionId: transcript.timestamp.millisecondsSinceEpoch.toString(),
        processingMethod: IntentProcessingMethod.mock,
        detectorVersion: 'mock-1.0',
        timestamp: timestamp,
      );
    }

    final intent = forcedIntent ?? (text.contains('help') || text.contains('emergency') ? EmergencyIntent.emergency : EmergencyIntent.nonEmergency);
    final confidence = forcedConfidence ?? (intent == EmergencyIntent.emergency ? 0.95 : 0.10);

    return EmergencyIntentResult(
      intent: intent,
      confidence: confidence,
      processingTimeMs: 2,
      language: transcript.language,
      sessionId: transcript.timestamp.millisecondsSinceEpoch.toString(),
      processingMethod: IntentProcessingMethod.mock,
      detectorVersion: 'mock-1.0',
      matchedPhrases: intent == EmergencyIntent.emergency ? ['help'] : [],
      timestamp: timestamp,
    );
  }

  @override
  void dispose() {}
}
