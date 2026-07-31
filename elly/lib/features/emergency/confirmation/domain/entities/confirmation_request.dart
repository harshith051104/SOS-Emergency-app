/// confirmation_request.dart
///
/// Immutable domain model containing input parameters for confirmation evaluation.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/decision_engine/domain/entities/decision_recommendation.dart';
import 'confirmation_method.dart';
import 'interruption_reason.dart';

@immutable
class ConfirmationRequest {
  const ConfirmationRequest({
    required this.sessionId,
    required this.recommendation,
    required this.emergencyConfidence,
    this.decisionReasons = const [],
    this.userResponse,
    this.responseMethod,
    this.wasTimedOut = false,
    this.wasInterrupted = false,
    this.interruptionReason = InterruptionReason.none,
    required this.timestamp,
  });

  final String sessionId;
  final DecisionRecommendation recommendation;
  final double emergencyConfidence;
  final List<String> decisionReasons;
  final String? userResponse;
  final ConfirmationMethod? responseMethod;
  final bool wasTimedOut;
  final bool wasInterrupted;
  final InterruptionReason interruptionReason;
  final DateTime timestamp;
}
