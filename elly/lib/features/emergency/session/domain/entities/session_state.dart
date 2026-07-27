/// session_state.dart
///
/// Enum defining the state machine lifecycle for an active emergency session.

library;

enum SessionState {
  idle,
  preparing,
  starting,
  active,
  paused,
  recovering,
  ending,
  completed,
  failed,
}
