/// session_lifecycle_state.dart
///
/// High-level session lifecycle states consumed by Phase 8 Emergency Session Activation.

library;

enum SessionLifecycleState {
  /// Session created and initialized
  created,

  /// Session active and waiting for user confirmation
  waitingForConfirmation,

  /// Emergency explicitly confirmed by user
  confirmed,

  /// Emergency explicitly cancelled by user
  cancelled,

  /// Confirmation countdown timed out
  timedOut,

  /// Confirmation process interrupted
  interrupted,

  /// Session finalized and closed
  closed,
}
