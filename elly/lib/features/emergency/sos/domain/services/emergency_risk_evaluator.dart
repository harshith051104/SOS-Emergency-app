/// emergency_risk_evaluator.dart
///
/// Domain service interface for AI-based emergency risk evaluation.
///
/// Phase 1: [MockEmergencyRiskEvaluator] always returns false, so the
/// confirmation screen is always shown.
///
/// Phase 2+ (AI/ML integration):
///   - Replace [MockEmergencyRiskEvaluator] with a real implementation
///     that evaluates sensor data, audio patterns, or biometrics.
///   - If [shouldSkipConfirmation] returns true, the [EmergencyController]
///     will skip the "Are you safe?" screen and activate SOS immediately,
///     treating the situation as a confirmed emergency.
///
/// This interface lives in the domain layer — it defines a contract the
/// data/infrastructure layer must fulfil without coupling the domain to
/// any specific AI SDK or API.

library;

/// Contract for evaluating whether the confirmation screen should be skipped.
abstract class EmergencyRiskEvaluator {
  /// Returns [true] if the system has determined with high confidence that
  /// the user is in an emergency and should not be interrupted with a
  /// "Are you safe?" prompt.
  ///
  /// When [true], [EmergencyController] activates SOS immediately.
  /// When [false] (default in Phase 1), the confirmation screen is shown.
  Future<bool> shouldSkipConfirmation();
}

// ── Phase 1 Mock Implementation ───────────────────────────────────────────────

/// Mock implementation that always returns false.
///
/// Replace this with a real AI/ML risk evaluator in Phase 2.
class MockEmergencyRiskEvaluator implements EmergencyRiskEvaluator {
  const MockEmergencyRiskEvaluator();

  /// Always returns false — confirmation screen always shown in Phase 1.
  @override
  Future<bool> shouldSkipConfirmation() async => false;
}
