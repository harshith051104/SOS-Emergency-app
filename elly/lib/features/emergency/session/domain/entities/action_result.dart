/// action_result.dart
///
/// Immutable domain model representing the execution output of an individual EmergencyAction.

library;

import 'package:flutter/foundation.dart';

@immutable
class ActionResult {
  const ActionResult({
    required this.actionId,
    required this.actionName,
    required this.success,
    required this.message,
    required this.executionTimeMs,
    required this.timestamp,
  });

  final String actionId;
  final String actionName;
  final bool success;
  final String message;
  final int executionTimeMs;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'actionId': actionId,
        'actionName': actionName,
        'success': success,
        'message': message,
        'executionTimeMs': executionTimeMs,
        'timestamp': timestamp.toIso8601String(),
      };
}
