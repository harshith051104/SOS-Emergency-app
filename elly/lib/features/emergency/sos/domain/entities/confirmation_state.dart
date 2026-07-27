/// confirmation_state.dart
///
/// Domain models, state machine enum, cancellation reasons, and rich analytics ConfirmationResult
/// with unique confirmationId tracking.

library;

import 'package:flutter/foundation.dart';

enum ConfirmationState {
  idle,
  awaitingResponse,
  confirmedSafe,
  confirmedEmergency,
  timeout,
  cancelled,
}

enum ConfirmationResponse {
  safe,
  emergency,
  none,
}

enum CancellationReason {
  userConfirmedSafe,
  manualCancel,
  appClosed,
  sessionSuperseded,
  configDisabled,
  none,
}

@immutable
class ConfirmationResult {
  const ConfirmationResult({
    required this.confirmationId,
    required this.response,
    this.cancellationReason = CancellationReason.none,
    required this.duration,
    required this.timeoutOccurred,
    required this.emergencyTriggered,
    this.confirmationMethod = 'button',
    this.confidence,
    required this.timestamp,
  });

  final String confirmationId;
  final ConfirmationResponse response;
  final CancellationReason cancellationReason;
  final Duration duration;
  final bool timeoutOccurred;
  final bool emergencyTriggered;
  final String confirmationMethod;
  final double? confidence;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'confirmationId': confirmationId,
      'response': response.name,
      'cancellationReason': cancellationReason.name,
      'durationMs': duration.inMilliseconds,
      'timeoutOccurred': timeoutOccurred,
      'emergencyTriggered': emergencyTriggered,
      'confirmationMethod': confirmationMethod,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ConfirmationResult.fromJson(Map<String, dynamic> json) {
    return ConfirmationResult(
      confirmationId: json['confirmationId'] as String? ?? 'CONF_LEGACY',
      response: ConfirmationResponse.values.firstWhere(
        (e) => e.name == json['response'],
        orElse: () => ConfirmationResponse.none,
      ),
      cancellationReason: CancellationReason.values.firstWhere(
        (e) => e.name == json['cancellationReason'],
        orElse: () => CancellationReason.none,
      ),
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      timeoutOccurred: json['timeoutOccurred'] as bool? ?? false,
      emergencyTriggered: json['emergencyTriggered'] as bool? ?? false,
      confirmationMethod: json['confirmationMethod'] as String? ?? 'button',
      confidence: (json['confidence'] as num?)?.toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
