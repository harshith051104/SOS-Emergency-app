/// vocal_biomarker_state.dart
///
/// Presentation state for the Vocal Biomarker module.

library;

import 'package:flutter/foundation.dart';
import 'vocal_biomarker_result.dart';
import 'vocal_biomarker_telemetry.dart';
import 'vocal_biomarker_error.dart';

enum VocalBiomarkerStatus {
  idle,
  analyzing,
  completed,
  failed,
}

@immutable
class VocalBiomarkerState {
  const VocalBiomarkerState({
    this.status = VocalBiomarkerStatus.idle,
    this.activeSessionId,
    this.lastResult,
    this.telemetry = const VocalBiomarkerTelemetry(),
    this.errorCategory,
    this.errorMessage,
  });

  final VocalBiomarkerStatus status;
  final String? activeSessionId;
  final VocalBiomarkerResult? lastResult;
  final VocalBiomarkerTelemetry telemetry;
  final VocalBiomarkerErrorCategory? errorCategory;
  final String? errorMessage;

  VocalBiomarkerState copyWith({
    VocalBiomarkerStatus? status,
    String? activeSessionId,
    VocalBiomarkerResult? lastResult,
    VocalBiomarkerTelemetry? telemetry,
    VocalBiomarkerErrorCategory? errorCategory,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VocalBiomarkerState(
      status: status ?? this.status,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      lastResult: lastResult ?? this.lastResult,
      telemetry: telemetry ?? this.telemetry,
      errorCategory: clearError ? null : (errorCategory ?? this.errorCategory),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
