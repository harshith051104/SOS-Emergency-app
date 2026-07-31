/// decision_recommendation.dart
///
/// Enumeration of objective emergency recommendations produced by the Decision Engine.

library;

enum DecisionRecommendation {
  /// Normal baseline activity (no indication of emergency)
  normal,

  /// Elevated vigilance / ambiguous signals (continue monitoring)
  monitor,

  /// High-probability emergency signal requiring user confirmation
  requestConfirmation,

  /// Critical high-risk emergency signal (immediate priority)
  highRisk,
}
