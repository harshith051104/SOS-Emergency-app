/// emergency_decision_request.dart
///
/// Immutable domain model containing aggregated multi-modal evidence for evaluation.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent_result.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_result.dart';
import 'package:elly/features/emergency/vocal_biomarkers/domain/entities/vocal_biomarker_result.dart';

@immutable
class EmergencyDecisionRequest {
  const EmergencyDecisionRequest({
    required this.sessionId,
    this.transcript,
    this.intentResult,
    this.intentTimestamp,
    this.speakerResult,
    this.speakerTimestamp,
    this.biomarkerResult,
    this.biomarkerTimestamp,
    this.vadConfidence,
    required this.timestamp,
  });

  final String sessionId;
  final String? transcript;
  final EmergencyIntentResult? intentResult;
  final DateTime? intentTimestamp;
  final SpeakerVerificationResult? speakerResult;
  final DateTime? speakerTimestamp;
  final VocalBiomarkerResult? biomarkerResult;
  final DateTime? biomarkerTimestamp;
  final double? vadConfidence;
  final DateTime timestamp;
}
