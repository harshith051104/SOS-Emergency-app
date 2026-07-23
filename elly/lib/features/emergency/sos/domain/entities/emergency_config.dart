/// emergency_config.dart
///
/// Runtime configuration for the Emergency feature.
/// All tuneable values live here — nothing is hardcoded in widgets or
/// business logic.
///
/// In a future phase these values can be driven by:
///   - Remote config (Firebase, LaunchDarkly)
///   - User preferences stored locally
///   - Backend-provided emergency policy

library;

import 'package:equatable/equatable.dart';

/// Immutable configuration governing emergency behaviour.
class EmergencyConfig extends Equatable {
  const EmergencyConfig({
    this.confirmationDuration = 10,
    this.countdownSeconds = 5,
    this.vibrationEnabled = true,
    this.soundEnabled = true,
  });

  /// Seconds the "Are you safe?" confirmation screen waits before
  /// auto-activating SOS. Used by the [awaitingConfirmation] flow.
  final int confirmationDuration;

  /// Seconds the legacy 5-second activation countdown runs before
  /// calling the backend. Used by the [countdown] (legacy) flow.
  final int countdownSeconds;

  /// Whether haptic feedback is used during state transitions.
  final bool vibrationEnabled;

  /// Whether tick / activation sounds are played.
  final bool soundEnabled;

  /// Returns a copy of this config with the given fields overridden.
  EmergencyConfig copyWith({
    int? confirmationDuration,
    int? countdownSeconds,
    bool? vibrationEnabled,
    bool? soundEnabled,
  }) {
    return EmergencyConfig(
      confirmationDuration: confirmationDuration ?? this.confirmationDuration,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  @override
  List<Object?> get props => [
        confirmationDuration,
        countdownSeconds,
        vibrationEnabled,
        soundEnabled,
      ];
}
