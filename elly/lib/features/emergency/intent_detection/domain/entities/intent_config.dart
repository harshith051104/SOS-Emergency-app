/// intent_config.dart
///
/// Configuration model for Emergency Intent Detection parameters and thresholds.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent.dart';

@immutable
class IntentConfig {
  const IntentConfig({
    this.detectorType = IntentProcessingMethod.ruleBased,
    this.emergencyThreshold = 0.75,
    this.possibleEmergencyThreshold = 0.45,
    this.supportedLanguages = const ['en', 'hi', 'te', 'ta', 'kn', 'ml'],
    this.maxProcessingTimeMs = 1000,
    this.detectorVersion = '1.0.0',
  });

  final IntentProcessingMethod detectorType;
  final double emergencyThreshold;
  final double possibleEmergencyThreshold;
  final List<String> supportedLanguages;
  final int maxProcessingTimeMs;
  final String detectorVersion;

  IntentConfig copyWith({
    IntentProcessingMethod? detectorType,
    double? emergencyThreshold,
    double? possibleEmergencyThreshold,
    List<String>? supportedLanguages,
    int? maxProcessingTimeMs,
    String? detectorVersion,
  }) {
    return IntentConfig(
      detectorType: detectorType ?? this.detectorType,
      emergencyThreshold: emergencyThreshold ?? this.emergencyThreshold,
      possibleEmergencyThreshold: possibleEmergencyThreshold ?? this.possibleEmergencyThreshold,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      maxProcessingTimeMs: maxProcessingTimeMs ?? this.maxProcessingTimeMs,
      detectorVersion: detectorVersion ?? this.detectorVersion,
    );
  }

  Map<String, dynamic> toJson() => {
        'detectorType': detectorType.name,
        'emergencyThreshold': emergencyThreshold,
        'possibleEmergencyThreshold': possibleEmergencyThreshold,
        'supportedLanguages': supportedLanguages,
        'maxProcessingTimeMs': maxProcessingTimeMs,
        'detectorVersion': detectorVersion,
      };
}
