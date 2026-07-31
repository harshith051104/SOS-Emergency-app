import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_state.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_config.dart';
import 'package:elly/features/emergency/speech_recognition/presentation/providers/speech_providers.dart';
import 'package:elly/features/emergency/speech_recognition/data/services/recognizers/mock_speech_recognizer.dart';

void main() {
  group('SpeechController Unit & Lifecycle Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          speechConfigProvider.overrideWith(
            (ref) => const SpeechConfig(engine: SpeechEngine.mock),
          ),
          speechRecognizerProvider.overrideWithValue(
            MockSpeechRecognizer(mockText: 'Test emergency transcript'),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is idle', () {
      final state = container.read(speechControllerProvider);

      expect(state.status, equals(SpeechStatus.idle));
      expect(state.lastTranscript, isNull);
      expect(state.confidence, equals(0.0));
    });

    test('Active transcription cancellation transitions state to cancelled', () async {
      final controller = container.read(speechControllerProvider.notifier);

      await controller.cancelActiveTranscription();
      final state = container.read(speechControllerProvider);

      expect(state.status, equals(SpeechStatus.cancelled));
    });
  });
}
