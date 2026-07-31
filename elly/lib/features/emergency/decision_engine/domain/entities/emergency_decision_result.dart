/// emergency_decision_result.dart
///
/// Immutable domain model containing the evaluated EmergencyDecisionResult and explainability data.

library;

import 'package:flutter/foundation.dart';
import 'decision_recommendation.dart';

@immutable
class EmergencyDecisionResult {
  const EmergencyDecisionResult({
    required this.sessionId,
    required this.emergencyConfidence,
    required this.recommendation,
    required this.evidenceUsed,
    required this.evidenceIgnored,
    required this.missingEvidence,
    required this.expiredEvidence,
    required this.decisionReasons,
    required this.ruleTrace,
    required this.processingTimeMs,
    this.engineVersion = 'v1.0.0-rules',
    this.algorithmVersion = 'v1.0.0-multi-signal',
    required this.timestamp,
  });

  final String sessionId;
  /// Final emergency confidence rating (0.0 to 1.0)
  final double emergencyConfidence;
  /// Recommended action level
  final DecisionRecommendation recommendation;
  /// List of signal evidence items successfully evaluated
  final List<String> evidenceUsed;
  /// List of signal evidence items ignored (e.g. low reliability)
  final List<String> evidenceIgnored;
  /// List of expected optional signal evidence items missing
  final List<String> missingEvidence;
  /// List of signal evidence items excluded due to age (> maxEvidenceAgeMs)
  final List<String> expiredEvidence;
  /// Human-readable explanation reasons for the decision
  final List<String> decisionReasons;
  /// Exact execution trace of rules evaluated
  final List<String> ruleTrace;
  /// Execution latency in milliseconds
  final int processingTimeMs;
  /// Decision engine version
  final String engineVersion;
  /// Decision algorithm version
  final String algorithmVersion;
  /// Timestamp of evaluation
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'emergencyConfidence': emergencyConfidence,
        'recommendation': recommendation.name,
        'evidenceUsed': evidenceUsed,
        'evidenceIgnored': evidenceIgnored,
        'missingEvidence': missingEvidence,
        'expiredEvidence': expiredEvidence,
        'decisionReasons': decisionReasons,
        'ruleTrace': ruleTrace,
        'processingTimeMs': processingTimeMs,
        'engineVersion': engineVersion,
        'algorithmVersion': algorithmVersion,
        'timestamp': timestamp.toIso8601String(),
      };
}
