/// conflict_resolution_strategy.dart
///
/// Enum defining conflict resolution policies for offline data synchronization.

library;

enum ConflictResolutionStrategy {
  serverWins,
  localWins,
  merge,
  manualReview,
}
