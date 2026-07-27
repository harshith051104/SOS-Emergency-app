/// retry_policy.dart
///
/// Exponential backoff policy calculator for offline emergency data packet synchronization.

library;

import 'package:elly/core/utils/app_clock.dart';

class RetryPolicy {
  static const int maxRetryAttempts = 10;

  /// Returns the next scheduled DateTime for retry attempt based on current retry count.
  /// Standard intervals: 1m ➔ 2m ➔ 5m ➔ 10m ➔ 30m.
  static DateTime getNextRetryTime({
    required int currentRetryCount,
    DateTime? fromTime,
  }) {
    final baseTime = fromTime ?? AppClock.now();
    Duration delay;

    switch (currentRetryCount) {
      case 0:
        delay = const Duration(minutes: 1);
      case 1:
        delay = const Duration(minutes: 2);
      case 2:
        delay = const Duration(minutes: 5);
      case 3:
        delay = const Duration(minutes: 10);
      default:
        delay = const Duration(minutes: 30);
    }

    return baseTime.add(delay);
  }

  /// Determines if a packet has exceeded maximum retry attempts.
  static bool hasExceededMaxRetries(int retryCount) {
    return retryCount >= maxRetryAttempts;
  }
}
