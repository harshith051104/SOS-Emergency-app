/// speech_providers.dart
///
/// Riverpod dependency injection definitions for Speech Recognition (STT) feature.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';
import 'package:elly/features/emergency/speech_recognition/domain/interfaces/i_speech_recognizer.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_config.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_state.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_telemetry.dart';
import 'package:elly/features/emergency/speech_recognition/data/services/speech_buffer_service.dart';
import 'package:elly/features/emergency/speech_recognition/data/services/speech_recognition_service.dart';
import 'package:elly/features/emergency/speech_recognition/data/services/recognizers/sherpa_speech_recognizer.dart';
import 'package:elly/features/emergency/speech_recognition/data/services/recognizers/whisper_speech_recognizer.dart';
import 'package:elly/features/emergency/speech_recognition/data/services/recognizers/mock_speech_recognizer.dart';
import 'package:elly/features/emergency/assistant/data/providers/assistant_providers.dart';
import 'package:elly/features/emergency/speech_recognition/presentation/controllers/speech_controller.dart';

final speechConfigProvider = StateProvider<SpeechConfig>((ref) {
  return const SpeechConfig();
});

/// Direct Riverpod DI Selection for SpeechRecognizer implementation.
final speechRecognizerProvider = Provider<SpeechRecognizer>((ref) {
  final config = ref.watch(speechConfigProvider);
  final groqKey = ref.watch(groqApiKeyProvider);
  switch (config.engine) {
    case SpeechEngine.sherpaSenseVoice:
      return SherpaSpeechRecognizer(config: config);
    case SpeechEngine.whisper:
      return WhisperSpeechRecognizer(config: config, apiKey: groqKey);
    case SpeechEngine.mock:
      return MockSpeechRecognizer();
  }
});

final speechBufferServiceProvider = Provider<SpeechBufferService>((ref) {
  final eventBus = ref.watch(emergencyEventBusProvider);
  final service = SpeechBufferService(eventBus: eventBus);
  ref.onDispose(() => service.dispose());
  return service;
});

final speechRecognitionServiceProvider = Provider<SpeechRecognitionService>((ref) {
  final recognizer = ref.watch(speechRecognizerProvider);
  final config = ref.watch(speechConfigProvider);

  final service = SpeechRecognitionService(
    recognizer: recognizer,
    timeoutSeconds: config.maxUtteranceSeconds,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final speechControllerProvider = StateNotifierProvider<SpeechController, SpeechState>((ref) {
  final bufferService = ref.watch(speechBufferServiceProvider);
  final recognitionService = ref.watch(speechRecognitionServiceProvider);

  return SpeechController(
    ref,
    bufferService: bufferService,
    recognitionService: recognitionService,
  );
});

final speechTelemetryProvider = Provider<SpeechTelemetry>((ref) {
  final service = ref.watch(speechRecognitionServiceProvider);
  return service.telemetry;
});
