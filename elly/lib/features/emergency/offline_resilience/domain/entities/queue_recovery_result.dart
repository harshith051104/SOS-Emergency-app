/// queue_recovery_result.dart
///
/// Immutable domain model summarizing the results of queue integrity verification and startup repair.

library;

import 'package:flutter/foundation.dart';

@immutable
class QueueRecoveryResult {
  const QueueRecoveryResult({
    required this.recoveredPackets,
    required this.discardedPackets,
    required this.repairedPackets,
    required this.recoveryDuration,
    required this.reason,
  });

  final int recoveredPackets;
  final int discardedPackets;
  final int repairedPackets;
  final Duration recoveryDuration;
  final String reason;

  Map<String, dynamic> toJson() => {
        'recoveredPackets': recoveredPackets,
        'discardedPackets': discardedPackets,
        'repairedPackets': repairedPackets,
        'recoveryDurationMs': recoveryDuration.inMilliseconds,
        'reason': reason,
      };
}
