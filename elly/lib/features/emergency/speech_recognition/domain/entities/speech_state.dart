/// speech_state.dart
///
/// Immutable domain state model representing STT engine lifecycle status.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_error.dart';

enum SpeechStatus {
  idle,
  listening,
  buffering,
  transcribing,
  completed,
  cancelled,
  error,
}

@immutable
class SpeechState {
  const SpeechState({
    this.status = SpeechStatus.idle,
    this.activeSessionId,
    this.lastTranscript,
    this.confidence = 0.0,
    this.lastInferenceTimeMs = 0,
    this.errorCategory = SpeechErrorCategory.none,
    this.errorMessage,
  });

  final SpeechStatus status;
  final String? activeSessionId;
  final String? lastTranscript;
  final double confidence;
  final int lastInferenceTimeMs;
  final SpeechErrorCategory errorCategory;
  final String? errorMessage;

  SpeechState copyWith({
    SpeechStatus? status,
    String? activeSessionId,
    String? lastTranscript,
    double? confidence,
    int? lastInferenceTimeMs,
    SpeechErrorCategory? errorCategory,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SpeechState(
      status: status ?? this.status,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      lastTranscript: lastTranscript ?? this.lastTranscript,
      confidence: confidence ?? this.confidence,
      lastInferenceTimeMs: lastInferenceTimeMs ?? this.lastInferenceTimeMs,
      errorCategory: clearError ? SpeechErrorCategory.none : (errorCategory ?? this.errorCategory),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
