/// i_speech_recognizer.dart
///
/// Abstraction interface for Speech-to-Text (STT) engines.

library;

import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_recognition_result.dart';

abstract class SpeechRecognizer {
  Future<SpeechRecognitionResult> transcribe(SpeechSession session);
  Future<void> cancelCurrentRecognition();
  void dispose();
}
