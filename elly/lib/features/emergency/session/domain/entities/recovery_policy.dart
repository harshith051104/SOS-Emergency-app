/// recovery_policy.dart
///
/// Failure recovery strategy policies for dynamic engine failure handling (Retry, Skip, Degrade, Abort).

library;

import 'package:flutter/foundation.dart';

enum RecoveryStrategy {
  retry,   // Re-attempt engine initialization
  skip,    // Skip failed optional engine and continue session
  degrade, // Transition engine to fallback degraded mode
  abort,   // Abort session completely
}

@immutable
class RecoveryPolicy {
  const RecoveryPolicy({
    required this.engineName,
    required this.strategy,
    this.maxRetries = 3,
    this.reason,
  });

  final String engineName;
  final RecoveryStrategy strategy;
  final int maxRetries;
  final String? reason;
}
class RecoveryAction {
  const RecoveryAction({
    required this.engineName,
    required this.strategy,
    required this.timestamp,
    this.appliedSuccess = true,
  });

  final String engineName;
  final RecoveryStrategy strategy;
  final DateTime timestamp;
  final bool appliedSuccess;
}
