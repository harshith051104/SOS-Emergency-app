/// confirmation_metrics.dart
///
/// Operational analytics metrics model capturing confirmation stats (response time, false alarms, timeouts).

library;

import 'package:flutter/foundation.dart';

@immutable
class ConfirmationMetrics {
  const ConfirmationMetrics({
    this.totalConfirmations = 0,
    this.safeConfirmations = 0,
    this.emergencyConfirmations = 0,
    this.timeouts = 0,
    this.highRiskBypasses = 0,
    this.averageResponseTimeMs = 0,
  });

  final int totalConfirmations;
  final int safeConfirmations;
  final int emergencyConfirmations;
  final int timeouts;
  final int highRiskBypasses;
  final int averageResponseTimeMs;

  double get falseAlarmRate =>
      totalConfirmations > 0 ? safeConfirmations / totalConfirmations : 0.0;

  double get timeoutRate =>
      totalConfirmations > 0 ? timeouts / totalConfirmations : 0.0;

  ConfirmationMetrics copyWith({
    int? totalConfirmations,
    int? safeConfirmations,
    int? emergencyConfirmations,
    int? timeouts,
    int? highRiskBypasses,
    int? averageResponseTimeMs,
  }) {
    return ConfirmationMetrics(
      totalConfirmations: totalConfirmations ?? this.totalConfirmations,
      safeConfirmations: safeConfirmations ?? this.safeConfirmations,
      emergencyConfirmations: emergencyConfirmations ?? this.emergencyConfirmations,
      timeouts: timeouts ?? this.timeouts,
      highRiskBypasses: highRiskBypasses ?? this.highRiskBypasses,
      averageResponseTimeMs: averageResponseTimeMs ?? this.averageResponseTimeMs,
    );
  }
}
