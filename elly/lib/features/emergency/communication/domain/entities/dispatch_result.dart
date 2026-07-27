/// dispatch_result.dart
///
/// Immutable domain model containing the outcome of an emergency communication operation.

library;

import 'package:flutter/foundation.dart';

@immutable
class DispatchResult {
  const DispatchResult({
    required this.success,
    required this.communicationMethod,
    required this.emergencyNumber,
    required this.startedAt,
    this.failureReason,
  });

  final bool success;
  final String communicationMethod;
  final String emergencyNumber;
  final DateTime startedAt;
  final String? failureReason;

  factory DispatchResult.successResult({
    required String emergencyNumber,
    String communicationMethod = 'NATIVE_DIALER',
  }) {
    return DispatchResult(
      success: true,
      communicationMethod: communicationMethod,
      emergencyNumber: emergencyNumber,
      startedAt: DateTime.now(),
    );
  }

  factory DispatchResult.failureResult({
    required String emergencyNumber,
    required String reason,
    String communicationMethod = 'NATIVE_DIALER',
  }) {
    return DispatchResult(
      success: false,
      communicationMethod: communicationMethod,
      emergencyNumber: emergencyNumber,
      startedAt: DateTime.now(),
      failureReason: reason,
    );
  }

  DispatchResult copyWith({
    bool? success,
    String? communicationMethod,
    String? emergencyNumber,
    DateTime? startedAt,
    String? failureReason,
  }) {
    return DispatchResult(
      success: success ?? this.success,
      communicationMethod: communicationMethod ?? this.communicationMethod,
      emergencyNumber: emergencyNumber ?? this.emergencyNumber,
      startedAt: startedAt ?? this.startedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}
