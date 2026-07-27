/// health_validation_result.dart
///
/// Domain validation result containing completeness score %, missing fields, and warnings.

library;

import 'package:flutter/foundation.dart';

@immutable
class HealthValidationResult {
  const HealthValidationResult({
    required this.success,
    this.missingFields = const [],
    this.warnings = const [],
    required this.completenessScore,
  });

  final bool success;
  final List<String> missingFields;
  final List<String> warnings;
  final int completenessScore;

  factory HealthValidationResult.valid(int score, List<String> warnings) =>
      HealthValidationResult(
        success: warnings.isEmpty,
        completenessScore: score,
        warnings: warnings,
      );

  factory HealthValidationResult.invalid({
    required List<String> missingFields,
    required List<String> warnings,
    required int score,
  }) =>
      HealthValidationResult(
        success: false,
        missingFields: missingFields,
        warnings: warnings,
        completenessScore: score,
      );
}
