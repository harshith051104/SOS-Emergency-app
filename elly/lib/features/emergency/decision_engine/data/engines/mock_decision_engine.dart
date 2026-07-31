/// mock_decision_engine.dart
///
/// Mock implementation of DecisionEngine for unit testing and instant UI simulation.

library;

import '../../domain/entities/emergency_decision_request.dart';
import '../../domain/entities/emergency_decision_result.dart';
import '../../domain/entities/decision_recommendation.dart';
import '../../domain/interfaces/i_decision_engine.dart';

class MockDecisionEngine implements DecisionEngine {
  MockDecisionEngine({
    this.mockResult,
    this.simulatedLatencyMs = 2,
  });

  final EmergencyDecisionResult? mockResult;
  final int simulatedLatencyMs;

  @override
  Future<EmergencyDecisionResult> evaluate(EmergencyDecisionRequest request) async {
    if (simulatedLatencyMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: simulatedLatencyMs));
    }

    if (mockResult != null) {
      return mockResult!;
    }

    return EmergencyDecisionResult(
      sessionId: request.sessionId,
      emergencyConfidence: 0.92,
      recommendation: DecisionRecommendation.requestConfirmation,
      evidenceUsed: const [
        'IntentResult (score: 0.98)',
        'SpeakerVerificationResult (match: true)',
        'VocalBiomarkerResult (stability: 0.88)'
      ],
      evidenceIgnored: const [],
      missingEvidence: const [],
      expiredEvidence: const [],
      decisionReasons: const [
        'High emergency intent detected ("help me")',
        'Speaker identity verified as enrolled device owner',
        'Acoustic indicators confirmed (Tension 28%, Instability 24%)'
      ],
      ruleTrace: const [
        'RULE_01_HIGH_INTENT: Intent score (0.98) >= 0.75.',
        'RULE_01A_SPEAKER_OWNER_VERIFIED: Speaker identity verified as device owner.',
        'RULE_01C_ACOUSTIC_STRESS_CONFIRMED: Acoustic tension/instability elevated.'
      ],
      processingTimeMs: simulatedLatencyMs,
      engineVersion: 'v1.0.0-mock',
      algorithmVersion: 'v1.0.0-mock',
      timestamp: DateTime.now(),
    );
  }

  @override
  void dispose() {}
}
