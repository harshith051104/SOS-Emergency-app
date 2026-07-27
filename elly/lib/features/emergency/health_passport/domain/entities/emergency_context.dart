/// emergency_context.dart
///
/// Shared immutable aggregate object containing emergency metadata and references to
/// HealthPassport, TelemetrySession, and SOSCircle across all platform engines.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/health_passport.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_session.dart';
import 'package:elly/features/emergency/sos_circle/domain/entities/sos_circle.dart';

@immutable
class EmergencyContext {
  const EmergencyContext({
    required this.sessionId,
    required this.dispatchId,
    required this.emergencyType,
    required this.startedAt,
    this.healthPassport,
    this.telemetrySession,
    this.sosCircle,
    this.highRisk = false,
    this.skipConfirmation = false,
  });

  final String sessionId;
  final String dispatchId;
  final String emergencyType;
  final DateTime startedAt;
  final HealthPassport? healthPassport;
  final TelemetrySession? telemetrySession;
  final SOSCircle? sosCircle;
  final bool highRisk;
  final bool skipConfirmation;

  EmergencyContext copyWith({
    String? sessionId,
    String? dispatchId,
    String? emergencyType,
    DateTime? startedAt,
    HealthPassport? healthPassport,
    TelemetrySession? telemetrySession,
    SOSCircle? sosCircle,
    bool? highRisk,
    bool? skipConfirmation,
  }) {
    return EmergencyContext(
      sessionId: sessionId ?? this.sessionId,
      dispatchId: dispatchId ?? this.dispatchId,
      emergencyType: emergencyType ?? this.emergencyType,
      startedAt: startedAt ?? this.startedAt,
      healthPassport: healthPassport ?? this.healthPassport,
      telemetrySession: telemetrySession ?? this.telemetrySession,
      sosCircle: sosCircle ?? this.sosCircle,
      highRisk: highRisk ?? this.highRisk,
      skipConfirmation: skipConfirmation ?? this.skipConfirmation,
    );
  }
}
