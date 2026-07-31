/// emergency_session_request.dart
///
/// Immutable domain model containing input parameters and confirmation results for Phase 8.

library;

import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_result.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_outcome.dart';

class EmergencySessionRequest {
  EmergencySessionRequest({
    required this.sessionId,
    required this.confirmationResult,
    required this.emergencyConfidence,
    required this.confirmationOutcome,
    this.decisionReasons = const [],
    Map<String, dynamic>? emergencyProfile,
    this.emergencyContacts = const [],
    required this.timestamp,
  }) : emergencyProfile = emergencyProfile ?? {};

  final String sessionId;
  final ConfirmationResult confirmationResult;
  final double emergencyConfidence;
  final ConfirmationOutcome confirmationOutcome;
  final List<String> decisionReasons;
  // Mutable so actions (e.g. LocationSharingAction) can write GPS into it
  final Map<String, dynamic> emergencyProfile;
  final List<String> emergencyContacts;
  final DateTime timestamp;
}

