/// emergency_status.dart
///
/// All possible lifecycle states for an [EmergencyEvent].
///
/// Lifecycle (new flow):
///   idle → awaitingConfirmation → generatingPacket → activating → active → sessionCompleted
///                                                            ↘ cancelled (user is safe)
///                                                            ↘ failed

library;

/// The status of an emergency event, from idle through to resolution.
enum EmergencyStatus {
  /// No active emergency. Default / reset state.
  idle,

  /// User tapped SOS. Full-screen "Are you safe?" page is visible.
  /// A configurable countdown (default: 10 s) runs automatically.
  /// If no response, SOS activates. Replaces the old bottom-sheet [confirmation].
  awaitingConfirmation,

  /// Verifying emergency details (time, location, medical profile) and creating
  /// the encrypted emergency packet.
  generatingPacket,

  /// Legacy: bottom-sheet confirmation was shown. Kept for backward compat.
  confirmation,

  /// Legacy: 5-second activation countdown is running.
  countdown,

  /// Countdown completed or user chose "No, I Need Help".
  /// Backend call / orchestration is in progress.
  activating,

  /// Emergency is live and active.
  active,

  /// Emergency was resolved / completed normally.
  completed,

  /// Emergency session completed and the final summary report is shown.
  sessionCompleted,

  /// User responded "Yes, I'm Safe" or cancelled before activation.
  cancelled,

  /// Activation failed (network timeout, backend error, etc.).
  failed,
}
