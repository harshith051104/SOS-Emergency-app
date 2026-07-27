/// sync_result.dart
///
/// Immutable domain model summarizing the execution result of an offline sync upload batch.

library;

import 'package:flutter/foundation.dart';

@immutable
class SyncResult {
  const SyncResult({
    required this.success,
    this.uploadedOperations = const [],
    this.failedOperations = const [],
    required this.duration,
    this.conflicts = const {},
  });

  final bool success;
  final List<String> uploadedOperations;
  final List<String> failedOperations;
  final Duration duration;
  final Map<String, String> conflicts;
}
