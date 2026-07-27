/// confirmation_policy.dart
///
/// Centralized decision policy engine determining whether anti-false trigger confirmation
/// should be displayed based on EmergencyContext, SosTriggerConfig, and risk factors.

library;

import 'package:elly/features/emergency/health_passport/domain/entities/emergency_context.dart';
import 'package:elly/features/emergency/sos/domain/entities/sos_trigger_config.dart';

class ConfirmationPolicy {
  /// Evaluates whether the confirmation screen should be presented.
  static bool shouldConfirm({
    required EmergencyContext context,
    required SosTriggerConfig config,
  }) {
    if (!config.isConfirmationEnabled) return false;
    if (context.skipConfirmation) return false;
    if (context.highRisk && config.skipConfirmationForHighRisk) return false;
    return true;
  }
}
