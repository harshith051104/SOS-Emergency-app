/// speech_config.dart
///
/// Configuration model for Speech-to-Text (STT) engine parameters.

library;

import 'package:flutter/foundation.dart';

enum SpeechEngine {
  sherpaSenseVoice,
  whisper,
  mock,
}

@immutable
class SpeechConfig {
  const SpeechConfig({
    this.engine = SpeechEngine.sherpaSenseVoice,   // ← backend Sherpa primary
    this.modelPath = 'sherpa-onnx-sense-voice-ctc', // ← informational label
    this.preferredLanguage = 'en',
    this.autoDetectLanguage = true,
    this.maxUtteranceSeconds = 30,
  });

  final SpeechEngine engine;
  final String modelPath;
  final String preferredLanguage;
  final bool autoDetectLanguage;
  final int maxUtteranceSeconds;

  SpeechConfig copyWith({
    SpeechEngine? engine,
    String? modelPath,
    String? preferredLanguage,
    bool? autoDetectLanguage,
    int? maxUtteranceSeconds,
  }) {
    return SpeechConfig(
      engine: engine ?? this.engine,
      modelPath: modelPath ?? this.modelPath,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      autoDetectLanguage: autoDetectLanguage ?? this.autoDetectLanguage,
      maxUtteranceSeconds: maxUtteranceSeconds ?? this.maxUtteranceSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'engine': engine.name,
        'modelPath': modelPath,
        'preferredLanguage': preferredLanguage,
        'autoDetectLanguage': autoDetectLanguage,
        'maxUtteranceSeconds': maxUtteranceSeconds,
      };
}
