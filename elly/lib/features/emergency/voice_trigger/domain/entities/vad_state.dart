/// vad_state.dart
///
/// Immutable domain state model representing the Voice Activity Detection engine status.

library;

import 'package:flutter/foundation.dart';

enum VadStatus {
  idle,
  starting,
  listening,
  speechDetected,
  paused,
  error,
  stopped,
  unsupported,
}

@immutable
class VadState {
  const VadState({
    this.status = VadStatus.idle,
    this.isServiceRunning = false,
    this.isSpeechDetected = false,
    this.lastSpeechDetectedAt,
    this.speechProbability = 0.0,
    this.speechThreshold = 0.5,
    this.errorMessage,
  });

  final VadStatus status;
  final bool isServiceRunning;
  final bool isSpeechDetected;
  final DateTime? lastSpeechDetectedAt;
  final double speechProbability;
  final double speechThreshold;
  final String? errorMessage;

  VadState copyWith({
    VadStatus? status,
    bool? isServiceRunning,
    bool? isSpeechDetected,
    DateTime? lastSpeechDetectedAt,
    double? speechProbability,
    double? speechThreshold,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VadState(
      status: status ?? this.status,
      isServiceRunning: isServiceRunning ?? this.isServiceRunning,
      isSpeechDetected: isSpeechDetected ?? this.isSpeechDetected,
      lastSpeechDetectedAt: lastSpeechDetectedAt ?? this.lastSpeechDetectedAt,
      speechProbability: speechProbability ?? this.speechProbability,
      speechThreshold: speechThreshold ?? this.speechThreshold,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
