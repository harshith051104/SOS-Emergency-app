/// severity_calculator.dart
///
/// Centralized domain calculator evaluating emergency severity (CRITICAL, HIGH, MEDIUM, LOW)
/// based on health profile risk, telemetry data, confirmation status, and symptoms.

library;

import 'package:elly/features/emergency/health_passport/domain/entities/emergency_health_profile.dart';
import 'package:elly/features/emergency/packet/domain/entities/emergency_symptoms_model.dart';
import 'package:elly/features/emergency/sos/domain/entities/confirmation_state.dart';

enum PacketSeverity {
  low,
  medium,
  high,
  critical,
}

class SeverityCalculator {
  static PacketSeverity calculate({
    required bool highRisk,
    EmergencyHealthProfile? profile,
    ConfirmationResult? confirmationResult,
    EmergencySymptomsModel symptoms = const EmergencySymptomsModel(),
  }) {
    if (highRisk || symptoms.unconscious || symptoms.breathingDifficulty) {
      return PacketSeverity.critical;
    }

    if (confirmationResult?.response == ConfirmationResponse.emergency) {
      return PacketSeverity.critical;
    }

    if (profile != null && profile.allergies.isNotEmpty && profile.chronicConditions.isNotEmpty) {
      return PacketSeverity.high;
    }

    if (confirmationResult?.timeoutOccurred == true) {
      return PacketSeverity.high;
    }

    return PacketSeverity.medium;
  }
}
