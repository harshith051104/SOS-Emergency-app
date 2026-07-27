/// readiness_report.dart
///
/// Domain model summarizing platform readiness score, level, missing permissions, and warnings.

library;

import 'package:flutter/foundation.dart';

enum ReadinessLevel {
  notReady,      // Score < 30%
  partial,       // Score 30-69%
  ready,         // Score 70-89%
  fullyPrepared, // Score >= 90%
}

@immutable
class ReadinessReport {
  const ReadinessReport({
    required this.readinessScore,
    required this.readinessLevel,
    required this.completedRequirements,
    required this.missingRequirements,
    required this.warnings,
    required this.recommendations,
  });

  final int readinessScore;
  final ReadinessLevel readinessLevel;
  final List<String> completedRequirements;
  final List<String> missingRequirements;
  final List<String> warnings;
  final List<String> recommendations;

  Map<String, dynamic> toJson() => {
        'readinessScore': readinessScore,
        'readinessLevel': readinessLevel.name,
        'completedRequirements': completedRequirements,
        'missingRequirements': missingRequirements,
        'warnings': warnings,
        'recommendations': recommendations,
      };
}
