/// emergency_intent_result.dart
///
/// Immutable domain model representing the output of an intent classification run.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent.dart';

@immutable
class EmergencyIntentResult {
  const EmergencyIntentResult({
    required this.intent,
    required this.confidence,
    required this.processingTimeMs,
    required this.language,
    required this.sessionId,
    required this.processingMethod,
    this.detectorVersion = '1.0.0',
    this.matchedPhrases = const [],
    required this.timestamp,
  });

  final EmergencyIntent intent;
  final double confidence;
  final int processingTimeMs;
  final String language;
  final String sessionId;
  final IntentProcessingMethod processingMethod;
  final String detectorVersion;
  final List<String> matchedPhrases;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'intent': intent.name,
        'confidence': confidence,
        'processingTimeMs': processingTimeMs,
        'language': language,
        'sessionId': sessionId,
        'processingMethod': processingMethod.name,
        'detectorVersion': detectorVersion,
        'matchedPhrases': matchedPhrases,
        'timestamp': timestamp.toIso8601String(),
      };
}
