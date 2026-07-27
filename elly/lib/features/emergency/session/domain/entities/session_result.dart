/// session_result.dart
///
/// Immutable domain model summarizing the execution result of an emergency session.

library;

import 'package:flutter/foundation.dart';

@immutable
class SessionResult {
  const SessionResult({
    required this.success,
    required this.duration,
    this.enginesStarted = const [],
    this.enginesStopped = const [],
    this.errors = const {},
  });

  final bool success;
  final Duration duration;
  final List<String> enginesStarted;
  final List<String> enginesStopped;
  final Map<String, String> errors;
}
