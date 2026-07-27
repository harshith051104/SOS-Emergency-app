/// emergency_severity.dart
///
/// Domain entity estimating situational risk severity level.

library;

import 'package:equatable/equatable.dart';

enum EmergencySeverityLevel {
  low,
  medium,
  high,
  critical,
}

class EmergencySeverity extends Equatable {
  const EmergencySeverity({
    required this.level,
    required this.score,
    required this.contributingFactors,
  });

  final EmergencySeverityLevel level;

  /// Risk score between 0 and 100.
  final int score;

  /// Explanatory factors triggering elevated risk (e.g. "Low Battery (8%)", "Internet Connection Lost").
  final List<String> contributingFactors;

  factory EmergencySeverity.defaultNormal() {
    return const EmergencySeverity(
      level: EmergencySeverityLevel.medium,
      score: 50,
      contributingFactors: ['SOS Active'],
    );
  }

  @override
  List<Object?> get props => [level, score, contributingFactors];
}
