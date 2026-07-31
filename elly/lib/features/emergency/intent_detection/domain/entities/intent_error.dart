/// intent_error.dart
///
/// Typed error classification enum and model for Intent Detection exceptions.

library;

import 'package:flutter/foundation.dart';

enum IntentErrorCategory {
  none,
  emptyTranscript,
  unsupportedLanguage,
  timeout,
  initializationFailure,
  parsingError,
}

@immutable
class IntentError {
  const IntentError({
    required this.category,
    required this.message,
    required this.timestamp,
  });

  final IntentErrorCategory category;
  final String message;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };
}
