/// synchronization_state.dart
///
/// Enum defining offline queue synchronization state.

library;

enum SynchronizationState {
  idle,
  waitingForConnection,
  syncing,
  synchronized,
  failed,
}
