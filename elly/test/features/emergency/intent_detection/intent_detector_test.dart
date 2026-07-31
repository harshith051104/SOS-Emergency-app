import 'package:flutter_test/flutter_test.dart';

import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_config.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_recognition_result.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/intent_config.dart';
import 'package:elly/features/emergency/intent_detection/data/services/detectors/rule_based_intent_detector.dart';
import 'package:elly/features/emergency/intent_detection/data/services/detectors/mock_intent_detector.dart';

void main() {
  group('IntentDetector Engine Unit Tests', () {
    late RuleBasedIntentDetector ruleDetector;
    late MockIntentDetector mockDetector;

    setUp(() {
      ruleDetector = RuleBasedIntentDetector(config: const IntentConfig());
      mockDetector = MockIntentDetector();
    });

    tearDown(() {
      ruleDetector.dispose();
      mockDetector.dispose();
    });

    SpeechRecognitionResult makeResult(String text, {String language = 'en'}) {
      return SpeechRecognitionResult(
        text: text,
        confidence: 0.95,
        durationMs: 2000,
        language: language,
        inferenceTimeMs: 40,
        engine: SpeechEngine.whisper,
        timestamp: DateTime.now(),
      );
    }

    test('Emergency phrases classify as EmergencyIntent.emergency', () async {
      final res1 = await ruleDetector.analyze(makeResult('Help me! I had an accident!'));
      expect(res1.intent, equals(EmergencyIntent.emergency));
      expect(res1.confidence, greaterThanOrEqualTo(0.85));

      final res2 = await ruleDetector.analyze(makeResult('मदद करो आपातकाल है', language: 'hi'));
      expect(res2.intent, equals(EmergencyIntent.emergency));
    });

    test('Mixed-language phrases classify correctly', () async {
      final res1 = await ruleDetector.analyze(makeResult('Please help, मेरी माँ गिर गई', language: 'hi'));
      expect(res1.intent, equals(EmergencyIntent.emergency));
      expect(res1.matchedPhrases, contains('help'));

      final res2 = await ruleDetector.analyze(makeResult('Help me, నాకు ప్రమాదం జరిగింది', language: 'te'));
      expect(res2.intent, equals(EmergencyIntent.emergency));
      expect(res2.matchedPhrases, contains('help'));
    });

    test('Non-emergency phrases classify as EmergencyIntent.nonEmergency', () async {
      final res = await ruleDetector.analyze(makeResult('What is the weather today?'));
      expect(res.intent, equals(EmergencyIntent.nonEmergency));
      expect(res.confidence, lessThan(0.50));
    });

    test('Empty transcript returns EmergencyIntent.unknown', () async {
      final res = await ruleDetector.analyze(makeResult('  '));
      expect(res.intent, equals(EmergencyIntent.unknown));
      expect(res.confidence, equals(0.0));
    });

    test('MockIntentDetector returns expected forced values', () async {
      final customMock = MockIntentDetector(
        forcedIntent: EmergencyIntent.possibleEmergency,
        forcedConfidence: 0.65,
      );

      final res = await customMock.analyze(makeResult('I fell down'));
      expect(res.intent, equals(EmergencyIntent.possibleEmergency));
      expect(res.confidence, equals(0.65));
      expect(res.processingMethod, equals(IntentProcessingMethod.mock));
    });
  });
}
