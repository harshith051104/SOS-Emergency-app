/// rule_based_intent_detector.dart
///
/// Implements [IntentDetector] for 100% offline baseline rule and phrase weight evaluation.

library;

import 'dart:async';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_recognition_result.dart';
import 'package:elly/features/emergency/intent_detection/domain/interfaces/i_intent_detector.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent_result.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/intent_config.dart';
import 'package:elly/features/emergency/intent_detection/data/resources/phrase_dictionary.dart';

class RuleBasedIntentDetector implements IntentDetector {
  RuleBasedIntentDetector({
    IntentConfig? config,
    List<String> customWakeWords = const [],
  })  : _config = config ?? const IntentConfig(),
        _customWakeWords = customWakeWords;

  final IntentConfig _config;
  final List<String> _customWakeWords;

  @override
  Future<EmergencyIntentResult> analyze(SpeechRecognitionResult transcript) async {
    final timestamp = DateTime.now();
    final stopwatch = Stopwatch()..start();

    final text = transcript.text.trim().toLowerCase();
    final lang = transcript.language.toLowerCase();

    if (text.isEmpty) {
      stopwatch.stop();
      return EmergencyIntentResult(
        intent: EmergencyIntent.unknown,
        confidence: 0.0,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        language: lang,
        sessionId: transcript.timestamp.millisecondsSinceEpoch.toString(),
        processingMethod: IntentProcessingMethod.ruleBased,
        detectorVersion: _config.detectorVersion,
        timestamp: timestamp,
      );
    }

    final matchedEmergency = <String>[];
    final matchedPossible = <String>[];

    // Check emergency phrases across preferred language, English, and custom wake words
    final emergencyList = [
      ..._customWakeWords,
      ...?PhraseDictionary.emergencyPhrases[lang],
      ...?PhraseDictionary.emergencyPhrases['en'],
    ];

    for (final phrase in emergencyList) {
      if (phrase.trim().isNotEmpty && text.contains(phrase.trim().toLowerCase())) {
        matchedEmergency.add(phrase);
      }
    }

    // Check possible emergency phrases
    final possibleList = [
      ...?PhraseDictionary.possibleEmergencyPhrases[lang],
      ...?PhraseDictionary.possibleEmergencyPhrases['en'],
    ];

    for (final phrase in possibleList) {
      if (text.contains(phrase.toLowerCase())) {
        matchedPossible.add(phrase);
      }
    }

    stopwatch.stop();
    final processingTimeMs = stopwatch.elapsedMilliseconds;

    EmergencyIntent intent;
    double confidence;
    final allMatches = [...matchedEmergency, ...matchedPossible];

    if (matchedEmergency.isNotEmpty) {
      intent = EmergencyIntent.emergency;
      confidence = (0.85 + (matchedEmergency.length * 0.05)).clamp(0.0, 0.99);
    } else if (matchedPossible.isNotEmpty) {
      intent = EmergencyIntent.possibleEmergency;
      confidence = (0.50 + (matchedPossible.length * 0.05)).clamp(0.0, 0.84);
    } else {
      intent = EmergencyIntent.nonEmergency;
      confidence = 0.15;
    }

    appLogger.info('RuleBasedIntentDetector: Analyzed "$text" -> Intent: ${intent.name} (conf: ${(confidence * 100).toStringAsFixed(1)}%, ${processingTimeMs}ms)');

    return EmergencyIntentResult(
      intent: intent,
      confidence: confidence,
      processingTimeMs: processingTimeMs,
      language: lang,
      sessionId: transcript.timestamp.millisecondsSinceEpoch.toString(),
      processingMethod: IntentProcessingMethod.ruleBased,
      detectorVersion: _config.detectorVersion,
      matchedPhrases: allMatches,
      timestamp: timestamp,
    );
  }

  @override
  void dispose() {}
}
