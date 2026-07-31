import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_config.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_recognition_result.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/intent_config.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/intent_state.dart';
import 'package:elly/features/emergency/intent_detection/presentation/providers/intent_providers.dart';
import 'package:elly/features/emergency/intent_detection/data/services/detectors/mock_intent_detector.dart';

void main() {
  group('IntentController Unit & Lifecycle Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          intentConfigProvider.overrideWith(
            (ref) => const IntentConfig(detectorType: IntentProcessingMethod.mock),
          ),
          intentDetectorProvider.overrideWithValue(
            MockIntentDetector(forcedIntent: EmergencyIntent.emergency, forcedConfidence: 0.98),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is idle', () {
      final state = container.read(intentControllerProvider);

      expect(state.status, equals(IntentStatus.idle));
      expect(state.lastResult, isNull);
    });

    test('analyzeTranscript updates state to completed with result', () async {
      final controller = container.read(intentControllerProvider.notifier);

      final speechResult = SpeechRecognitionResult(
        text: 'Emergency! Send help!',
        confidence: 0.95,
        durationMs: 1500,
        language: 'en',
        inferenceTimeMs: 30,
        engine: SpeechEngine.whisper,
        timestamp: DateTime.now(),
      );

      await controller.analyzeTranscript(speechResult);

      final state = container.read(intentControllerProvider);
      expect(state.status, equals(IntentStatus.completed));
      expect(state.lastResult, isNotNull);
      expect(state.lastResult!.intent, equals(EmergencyIntent.emergency));
      expect(state.lastResult!.confidence, equals(0.98));
    });
  });
}
