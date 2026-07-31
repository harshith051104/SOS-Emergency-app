/// speech_error.dart
///
/// Typed error classification enum and model for Speech Recognition exceptions.

library;

import 'package:flutter/foundation.dart';

enum SpeechErrorCategory {
  none,
  modelLoadFailure,
  timeout,
  cancelled,
  invalidAudio,
  unsupportedPlatform,
  inferenceFailure,
}

@immutable
class SpeechError {
  const SpeechError({
    required this.category,
    required this.message,
    required this.timestamp,
  });

  final SpeechErrorCategory category;
  final String message;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };
}
