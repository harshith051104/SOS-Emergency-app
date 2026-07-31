/// decision_engine_test.dart
///
/// Unit tests for RuleBasedDecisionEngine, MockDecisionEngine, and DecisionService.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent_result.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_result.dart';
import 'package:elly/features/emergency/vocal_biomarkers/domain/entities/vocal_biomarker_result.dart';
import 'package:elly/features/emergency/decision_engine/domain/entities/emergency_decision_request.dart';
import 'package:elly/features/emergency/decision_engine/domain/entities/decision_recommendation.dart';
import 'package:elly/features/emergency/decision_engine/data/engines/rule_based_decision_engine.dart';
import 'package:elly/features/emergency/decision_engine/data/engines/mock_decision_engine.dart';
import 'package:elly/features/emergency/decision_engine/data/services/decision_service.dart';

void main() {
  group('DecisionEngine Unit Tests', () {
    late RuleBasedDecisionEngine ruleEngine;
    late MockDecisionEngine mockEngine;

    setUp(() {
      ruleEngine = RuleBasedDecisionEngine();
      mockEngine = MockDecisionEngine();
    });

    tearDown(() {
      ruleEngine.dispose();
      mockEngine.dispose();
    });

    test('MockDecisionEngine returns expected mock decision recommendation', () async {
      final request = EmergencyDecisionRequest(
        sessionId: 'test_session_1',
        timestamp: DateTime.now(),
      );

      final result = await mockEngine.evaluate(request);

      expect(result.sessionId, equals('test_session_1'));
      expect(result.recommendation, equals(DecisionRecommendation.requestConfirmation));
      expect(result.emergencyConfidence, greaterThan(0.80));
      expect(result.evidenceUsed, isNotEmpty);
      expect(result.decisionReasons, isNotEmpty);
      expect(result.ruleTrace, isNotEmpty);
    });

    test('RuleBasedDecisionEngine evaluates high intent + verified speaker as REQUEST_CONFIRMATION / HIGH_RISK', () async {
      final now = DateTime.now();
      final request = EmergencyDecisionRequest(
        sessionId: 'emergency_session_high',
        transcript: 'help me emergency',
        intentResult: EmergencyIntentResult(
          sessionId: 'emergency_session_high',
          intent: EmergencyIntent.emergency,
          confidence: 0.95,
          processingTimeMs: 10,
          language: 'en',
          processingMethod: IntentProcessingMethod.ruleBased,
          matchedPhrases: const ['help me'],
          timestamp: now,
        ),
        intentTimestamp: now,
        speakerResult: SpeakerVerificationResult(
          sessionId: 'emergency_session_high',
          match: true,
          confidence: 0.94,
          profileId: 'prof_user',
          processingTimeMs: 15,
          embeddingVersion: 'v1.0.0',
          processingMethod: SpeakerVerificationMethod.embedding,
          timestamp: now,
        ),
        speakerTimestamp: now,
        biomarkerResult: VocalBiomarkerResult(
          sessionId: 'emergency_session_high',
          vocalTension: 0.65,
          speechInstability: 0.55,
          breathingIrregularity: 0.40,
          pitchVariability: 25.0,
          energyVariability: 0.60,
          jitter: 3.5,
          shimmer: 5.2,
          harmonicsToNoiseRatio: 14.0,
          spectralCentroid: 1800.0,
          voiceStability: 0.40,
          confidence: 0.90,
          processingTimeMs: 12,
          processingMethod: 'FEATURE_BASED_DSP',
          timestamp: now,
        ),
        biomarkerTimestamp: now,
        timestamp: now,
      );

      final result = await ruleEngine.evaluate(request);

      expect(result.sessionId, equals('emergency_session_high'));
      expect(result.emergencyConfidence, greaterThanOrEqualTo(0.85));
      expect(
        result.recommendation == DecisionRecommendation.requestConfirmation ||
            result.recommendation == DecisionRecommendation.highRisk,
        isTrue,
      );
      expect(result.evidenceUsed, contains(contains('EmergencyIntentResult')));
      expect(result.evidenceUsed, contains(contains('SpeakerVerificationResult')));
      expect(result.decisionReasons, isNotEmpty);
      expect(result.ruleTrace, isNotEmpty);
    });

    test('RuleBasedDecisionEngine penalizes unverified speaker match', () async {
      final now = DateTime.now();
      final request = EmergencyDecisionRequest(
        sessionId: 'unverified_speaker_session',
        intentResult: EmergencyIntentResult(
          sessionId: 'unverified_speaker_session',
          intent: EmergencyIntent.emergency,
          confidence: 0.85,
          processingTimeMs: 10,
          language: 'en',
          processingMethod: IntentProcessingMethod.ruleBased,
          matchedPhrases: const ['sos'],
          timestamp: now,
        ),
        intentTimestamp: now,
        speakerResult: SpeakerVerificationResult(
          sessionId: 'unverified_speaker_session',
          match: false, // Match failed
          confidence: 0.80,
          profileId: 'prof_user',
          processingTimeMs: 15,
          embeddingVersion: 'v1.0.0',
          processingMethod: SpeakerVerificationMethod.embedding,
          timestamp: now,
        ),
        speakerTimestamp: now,
        timestamp: now,
      );

      final result = await ruleEngine.evaluate(request);

      expect(result.decisionReasons, contains(contains('Unverified / unknown speaker')));
      expect(result.emergencyConfidence, lessThan(0.85));
    });

    test('RuleBasedDecisionEngine expires stale evidence older than maxEvidenceAgeMs', () async {
      final now = DateTime.now();
      final staleTime = now.subtract(const Duration(seconds: 10)); // 10s old > 5s max age

      final request = EmergencyDecisionRequest(
        sessionId: 'stale_evidence_session',
        intentResult: EmergencyIntentResult(
          sessionId: 'stale_evidence_session',
          intent: EmergencyIntent.emergency,
          confidence: 0.90,
          processingTimeMs: 10,
          language: 'en',
          processingMethod: IntentProcessingMethod.ruleBased,
          matchedPhrases: const ['help'],
          timestamp: staleTime,
        ),
        intentTimestamp: staleTime, // Stale!
        timestamp: now,
      );

      final result = await ruleEngine.evaluate(request);

      expect(result.expiredEvidence, contains(contains('Intent')));
      expect(result.recommendation, equals(DecisionRecommendation.normal));
    });

    test('DecisionService tracks telemetry stats upon evaluation', () async {
      final service = DecisionService(
        engine: mockEngine,
      );

      final request = EmergencyDecisionRequest(
        sessionId: 'telemetry_session',
        timestamp: DateTime.now(),
      );

      await service.processRequest(request);

      expect(service.telemetry.evaluationCount, equals(1));
      expect(service.telemetry.failureCount, equals(0));
      expect(service.telemetry.averageConfidence, greaterThan(0.0));
    });
  });
}
