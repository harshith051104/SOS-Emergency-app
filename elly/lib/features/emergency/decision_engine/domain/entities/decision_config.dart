/// decision_config.dart
///
/// Configuration thresholds and limits for the Multi-Signal Decision Engine.

library;

import 'package:flutter/foundation.dart';

@immutable
class DecisionConfig {
  const DecisionConfig({
    this.highRiskThreshold = 0.85,
    this.confirmationThreshold = 0.60,
    this.monitorThreshold = 0.35,
    this.maxEvidenceAgeMs = 5000,
    this.maxLatencyMs = 100,
  });

  /// Confidence threshold for HIGH_RISK recommendation
  final double highRiskThreshold;

  /// Confidence threshold for REQUEST_CONFIRMATION recommendation
  final double confirmationThreshold;

  /// Confidence threshold for MONITOR recommendation
  final double monitorThreshold;

  /// Maximum allowable age of evidence signals in milliseconds before expiring
  final int maxEvidenceAgeMs;

  /// Target maximum evaluation latency in milliseconds
  final int maxLatencyMs;
}
