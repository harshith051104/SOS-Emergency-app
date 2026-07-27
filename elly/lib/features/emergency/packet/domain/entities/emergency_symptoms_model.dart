/// emergency_symptoms_model.dart
///
/// Domain model holding symptom flags and distress scores (prepared for Sprint 10 AI detection).

library;

import 'package:flutter/foundation.dart';

@immutable
class EmergencySymptomsModel {
  const EmergencySymptomsModel({
    this.breathingDifficulty = false,
    this.unconscious = false,
    this.panicDetected = false,
    this.voiceDistressScore,
    this.faceDistressScore,
  });

  final bool breathingDifficulty;
  final bool unconscious;
  final bool panicDetected;
  final double? voiceDistressScore;
  final double? faceDistressScore;

  EmergencySymptomsModel copyWith({
    bool? breathingDifficulty,
    bool? unconscious,
    bool? panicDetected,
    double? voiceDistressScore,
    double? faceDistressScore,
  }) {
    return EmergencySymptomsModel(
      breathingDifficulty: breathingDifficulty ?? this.breathingDifficulty,
      unconscious: unconscious ?? this.unconscious,
      panicDetected: panicDetected ?? this.panicDetected,
      voiceDistressScore: voiceDistressScore ?? this.voiceDistressScore,
      faceDistressScore: faceDistressScore ?? this.faceDistressScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'breathingDifficulty': breathingDifficulty,
      'unconscious': unconscious,
      'panicDetected': panicDetected,
      'voiceDistressScore': voiceDistressScore,
      'faceDistressScore': faceDistressScore,
    };
  }

  factory EmergencySymptomsModel.fromJson(Map<String, dynamic> json) {
    return EmergencySymptomsModel(
      breathingDifficulty: json['breathingDifficulty'] as bool? ?? false,
      unconscious: json['unconscious'] as bool? ?? false,
      panicDetected: json['panicDetected'] as bool? ?? false,
      voiceDistressScore: (json['voiceDistressScore'] as num?)?.toDouble(),
      faceDistressScore: (json['faceDistressScore'] as num?)?.toDouble(),
    );
  }
}
