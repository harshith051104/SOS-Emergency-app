/// confirmation_strategy.dart
///
/// Encapsulates confirmation timeout durations, UI capabilities, and retry permissions
/// based on Phase 6 decision recommendations.

library;

import 'package:flutter/foundation.dart';

@immutable
abstract class ConfirmationStrategy {
  const ConfirmationStrategy({
    required this.name,
    required this.timeout,
    required this.allowVoice,
    required this.allowButtons,
    required this.allowRetry,
  });

  final String name;
  final Duration timeout;
  final bool allowVoice;
  final bool allowButtons;
  final bool allowRetry;
}

class NormalStrategy extends ConfirmationStrategy {
  const NormalStrategy()
      : super(
          name: 'NORMAL',
          timeout: Duration.zero,
          allowVoice: false,
          allowButtons: false,
          allowRetry: false,
        );
}

class MonitorStrategy extends ConfirmationStrategy {
  const MonitorStrategy()
      : super(
          name: 'MONITOR',
          timeout: Duration.zero,
          allowVoice: false,
          allowButtons: false,
          allowRetry: false,
        );
}

class RequestConfirmationStrategy extends ConfirmationStrategy {
  const RequestConfirmationStrategy({super.timeout = const Duration(seconds: 10)})
      : super(
          name: 'REQUEST_CONFIRMATION',
          allowVoice: true,
          allowButtons: true,
          allowRetry: true,
        );
}

class HighRiskStrategy extends ConfirmationStrategy {
  const HighRiskStrategy({super.timeout = const Duration(seconds: 5)})
      : super(
          name: 'HIGH_RISK',
          allowVoice: true,
          allowButtons: true,
          allowRetry: false,
        );
}
