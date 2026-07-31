/// confirmation_config.dart
///
/// Configuration parameters for the Confirmation Engine.

library;

import 'package:flutter/foundation.dart';

@immutable
class ConfirmationConfig {
  const ConfirmationConfig({
    this.requestConfirmationTimeoutMs = 10000,
    this.highRiskTimeoutMs = 5000,
    this.voiceConfirmationEnabled = true,
    this.buttonConfirmationEnabled = true,
    this.allowCancellation = true,
    this.maxRetries = 3,
  });

  /// Timeout in milliseconds for REQUEST_CONFIRMATION recommendation (10s)
  final int requestConfirmationTimeoutMs;

  /// Timeout in milliseconds for HIGH_RISK recommendation (5s)
  final int highRiskTimeoutMs;

  /// Whether voice interaction confirmation is enabled
  final bool voiceConfirmationEnabled;

  /// Whether manual button confirmation is enabled
  final bool buttonConfirmationEnabled;

  /// Whether user is allowed to cancel active countdown
  final bool allowCancellation;

  /// Maximum allowed confirmation retries
  final int maxRetries;
}
