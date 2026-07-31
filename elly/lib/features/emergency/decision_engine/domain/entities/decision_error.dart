/// decision_error.dart
///
/// Strongly typed error categories and exception class for Decision Engine.

library;

enum DecisionErrorCategory {
  missingRequiredEvidence,
  timeout,
  evaluationFailure,
}

class DecisionError implements Exception {
  const DecisionError(this.category, this.message);

  final DecisionErrorCategory category;
  final String message;

  @override
  String toString() => 'DecisionError[${category.name}]: $message';
}
