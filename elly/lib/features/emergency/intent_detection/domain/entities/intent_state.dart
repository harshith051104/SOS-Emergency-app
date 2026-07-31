/// intent_state.dart
///
/// Immutable domain presentation state representing intent classification status.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent_result.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/intent_error.dart';

enum IntentStatus {
  idle,
  analyzing,
  completed,
  error,
}

@immutable
class IntentState {
  const IntentState({
    this.status = IntentStatus.idle,
    this.activeSessionId,
    this.lastResult,
    this.errorCategory = IntentErrorCategory.none,
    this.errorMessage,
  });

  final IntentStatus status;
  final String? activeSessionId;
  final EmergencyIntentResult? lastResult;
  final IntentErrorCategory errorCategory;
  final String? errorMessage;

  IntentState copyWith({
    IntentStatus? status,
    String? activeSessionId,
    EmergencyIntentResult? lastResult,
    IntentErrorCategory? errorCategory,
    String? errorMessage,
    bool clearError = false,
  }) {
    return IntentState(
      status: status ?? this.status,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      lastResult: lastResult ?? this.lastResult,
      errorCategory: clearError ? IntentErrorCategory.none : (errorCategory ?? this.errorCategory),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
