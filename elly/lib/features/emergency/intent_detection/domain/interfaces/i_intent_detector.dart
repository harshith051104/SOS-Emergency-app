/// i_intent_detector.dart
///
/// Abstraction interface for Emergency Intent Detector engines.
/// Enables swapping rule-based, local model, or mock detectors via Riverpod DI.

library;

import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_recognition_result.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent_result.dart';

abstract class IntentDetector {
  Future<EmergencyIntentResult> analyze(SpeechRecognitionResult transcript);
  void dispose();
}
