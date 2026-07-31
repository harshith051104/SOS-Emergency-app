/// rule_based_decision_engine.dart
///
/// Deterministic, 100% offline, explainable multi-signal evidence evaluation engine.
/// Evaluates Intent, Speaker Verification, Vocal Biomarkers, and VAD signals.

library;

import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent.dart';
import '../../domain/entities/emergency_decision_request.dart';
import '../../domain/entities/emergency_decision_result.dart';
import '../../domain/entities/decision_recommendation.dart';
import '../../domain/entities/decision_config.dart';
import '../../domain/interfaces/i_decision_engine.dart';

class RuleBasedDecisionEngine implements DecisionEngine {
  RuleBasedDecisionEngine({
    DecisionConfig config = const DecisionConfig(),
  }) : _config = config;

  final DecisionConfig _config;

  static const String engineVersionConst = 'v1.0.0-rules';
  static const String algorithmVersionConst = 'v1.0.0-multi-signal';

  @override
  Future<EmergencyDecisionResult> evaluate(EmergencyDecisionRequest request) async {
    final stopwatch = Stopwatch()..start();
    final now = DateTime.now();

    final List<String> evidenceUsed = [];
    final List<String> evidenceIgnored = [];
    final List<String> missingEvidence = [];
    final List<String> expiredEvidence = [];
    final List<String> decisionReasons = [];
    final List<String> ruleTrace = [];

    // --- 1. Freshness Checks ---
    final intentFresh = _checkFreshness('Intent', request.intentTimestamp, now, expiredEvidence);
    final speakerFresh = _checkFreshness('Speaker', request.speakerTimestamp, now, expiredEvidence);
    final biomarkerFresh = _checkFreshness('Biomarker', request.biomarkerTimestamp, now, expiredEvidence);

    // --- 2. Required vs Optional Evidence Filter ---
    final hasIntent = request.intentResult != null && intentFresh;
    final hasSpeaker = request.speakerResult != null && speakerFresh;
    final hasBiomarkers = request.biomarkerResult != null && biomarkerFresh;

    if (!hasIntent) {
      missingEvidence.add('EmergencyIntentResult');
    }
    if (!hasSpeaker) {
      missingEvidence.add('SpeakerVerificationResult');
    }
    if (!hasBiomarkers) {
      missingEvidence.add('VocalBiomarkerResult');
    }

    // Default Baseline Output
    double emergencyConfidence = 0.05;
    DecisionRecommendation recommendation = DecisionRecommendation.normal;

    if (!hasIntent) {
      ruleTrace.add('RULE_00_NO_REQUIRED_INTENT: Missing required emergency intent evidence.');
      decisionReasons.add('No valid emergency speech intent evidence detected.');
      stopwatch.stop();

      return EmergencyDecisionResult(
        sessionId: request.sessionId,
        emergencyConfidence: emergencyConfidence,
        recommendation: recommendation,
        evidenceUsed: evidenceUsed,
        evidenceIgnored: evidenceIgnored,
        missingEvidence: missingEvidence,
        expiredEvidence: expiredEvidence,
        decisionReasons: decisionReasons,
        ruleTrace: ruleTrace,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        timestamp: DateTime.now(),
      );
    }

    final intent = request.intentResult!;
    evidenceUsed.add('EmergencyIntentResult (intent: ${intent.intent.name}, conf: ${intent.confidence.toStringAsFixed(2)})');

    // --- 3. Deterministic Evidence-Based Rule Evaluation ---

    // Rule 04: Non-Emergency / Low Intent Baseline
    if (intent.intent == EmergencyIntent.nonEmergency || intent.confidence < 0.35) {
      ruleTrace.add('RULE_04_LOW_INTENT: Intent (${intent.intent.name}) score (${intent.confidence}) < 0.35 threshold.');
      decisionReasons.add('Speech utterance evaluated as normal baseline intent.');
      emergencyConfidence = 0.08;
      recommendation = DecisionRecommendation.normal;
    } 
    // Rule 01: High Emergency Intent Match
    else if (intent.intent == EmergencyIntent.emergency || intent.confidence >= 0.75) {
      ruleTrace.add('RULE_01_HIGH_INTENT: Intent (${intent.intent.name}) confidence (${intent.confidence}) >= 0.75.');
      decisionReasons.add('High emergency intent detected ("${intent.matchedPhrases.isNotEmpty ? intent.matchedPhrases.first : 'Emergency phrase'}")');
      emergencyConfidence = intent.confidence;
      recommendation = DecisionRecommendation.requestConfirmation;

      // Speaker Verification Evidence Synergy
      if (hasSpeaker) {
        final spk = request.speakerResult!;
        if (spk.confidence >= 0.50) {
          evidenceUsed.add('SpeakerVerificationResult (match: ${spk.match})');
          if (spk.match) {
            ruleTrace.add('RULE_01A_SPEAKER_OWNER_VERIFIED: Speaker identity verified as device owner.');
            decisionReasons.add('Speaker identity verified as enrolled device owner');
            emergencyConfidence = (emergencyConfidence + 0.10).clamp(0.0, 0.98);
            if (emergencyConfidence >= _config.highRiskThreshold) {
              recommendation = DecisionRecommendation.highRisk;
            }
          } else {
            ruleTrace.add('RULE_01B_SPEAKER_UNVERIFIED_GUARD: Non-owner voice detected.');
            decisionReasons.add('Non-owner voice detected — SOS trigger ignored for speaker protection');
            emergencyConfidence = 0.05;
            recommendation = DecisionRecommendation.normal;
          }
        } else {
          evidenceIgnored.add('SpeakerVerificationResult (confidence ${spk.confidence} < 0.50)');
        }
      }

      // Vocal Biomarker Acoustic Stress Synergy
      if (hasBiomarkers) {
        final bio = request.biomarkerResult!;
        if (bio.confidence >= 0.50) {
          evidenceUsed.add('VocalBiomarkerResult (stability: ${bio.voiceStability})');
          if (bio.vocalTension > 0.40 || bio.speechInstability > 0.40 || bio.breathingIrregularity > 0.30) {
            ruleTrace.add('RULE_01C_ACOUSTIC_STRESS_CONFIRMED: Acoustic tension/instability elevated.');
            decisionReasons.add(
              'Acoustic indicators confirmed: Tension ${(bio.vocalTension * 100).toInt()}%, '
              'Instability ${(bio.speechInstability * 100).toInt()}%, Breathing Irregularity ${(bio.breathingIrregularity * 100).toInt()}%',
            );
            emergencyConfidence = (emergencyConfidence + 0.08).clamp(0.0, 0.99);
            if (emergencyConfidence >= _config.highRiskThreshold) {
              recommendation = DecisionRecommendation.highRisk;
            }
          }
        } else {
          evidenceIgnored.add('VocalBiomarkerResult (confidence ${bio.confidence} < 0.50)');
        }
      }
    } 
    // Rule 02: Ambiguous / Moderate Intent Match
    else {
      ruleTrace.add('RULE_02_MODERATE_INTENT: Intent (${intent.intent.name}) score (${intent.confidence}) between 0.35 and 0.75.');
      decisionReasons.add('Moderate emergency intent score (${(intent.confidence * 100).toInt()}%)');
      emergencyConfidence = intent.confidence;
      recommendation = DecisionRecommendation.monitor;

      if (hasBiomarkers) {
        final bio = request.biomarkerResult!;
        if (bio.confidence >= 0.50 && (bio.vocalTension > 0.50 || bio.speechInstability > 0.50)) {
          evidenceUsed.add('VocalBiomarkerResult (elevated acoustic stress)');
          ruleTrace.add('RULE_02A_BIOMARKER_ELEVATION: Elevated acoustic tension boosted confidence.');
          decisionReasons.add('Elevated acoustic stress detected during moderate intent');
          emergencyConfidence = (emergencyConfidence + 0.15).clamp(0.0, 0.85);
          if (emergencyConfidence >= _config.confirmationThreshold) {
            recommendation = DecisionRecommendation.requestConfirmation;
          }
        }
      }
    }

    stopwatch.stop();

    return EmergencyDecisionResult(
      sessionId: request.sessionId,
      emergencyConfidence: _round(emergencyConfidence),
      recommendation: recommendation,
      evidenceUsed: evidenceUsed,
      evidenceIgnored: evidenceIgnored,
      missingEvidence: missingEvidence,
      expiredEvidence: expiredEvidence,
      decisionReasons: decisionReasons,
      ruleTrace: ruleTrace,
      processingTimeMs: stopwatch.elapsedMilliseconds,
      timestamp: DateTime.now(),
    );
  }

  bool _checkFreshness(String name, DateTime? timestamp, DateTime now, List<String> expiredList) {
    if (timestamp == null) return true;
    final ageMs = now.difference(timestamp).inMilliseconds;
    if (ageMs > _config.maxEvidenceAgeMs) {
      expiredList.add('$name (age: ${ageMs}ms > ${_config.maxEvidenceAgeMs}ms)');
      return false;
    }
    return true;
  }

  double _round(double val) => (val * 1000).round() / 1000.0;

  @override
  void dispose() {}
}
