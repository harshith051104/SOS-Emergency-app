/// sos_notification_result.dart
///
/// Immutable domain result summary of an SOS Circle notification execution run.

library;

import 'package:flutter/foundation.dart';

@immutable
class SOSNotificationResult {
  const SOSNotificationResult({
    required this.success,
    required this.notifiedContacts,
    required this.failedContacts,
    required this.startedAt,
    required this.completedAt,
    required this.failures,
  });

  final bool success;
  final List<String> notifiedContacts;
  final List<String> failedContacts;
  final DateTime startedAt;
  final DateTime completedAt;
  final Map<String, String> failures;
}
