/// speaker_verification_state.dart
///
/// Immutable domain presentation state model representing Speaker Verification status.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_profile.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_result.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_error.dart';

enum SpeakerVerificationStatus {
  idle,
  verifying,
  completed,
  failed,
}

@immutable
class SpeakerVerificationState {
  const SpeakerVerificationState({
    this.status = SpeakerVerificationStatus.idle,
    this.activeSessionId,
    this.lastResult,
    this.activeProfile,
    this.enrolledProfiles = const [],
    this.errorCategory = SpeakerVerificationErrorCategory.none,
    this.errorMessage,
  });

  final SpeakerVerificationStatus status;
  final String? activeSessionId;
  final SpeakerVerificationResult? lastResult;
  final SpeakerProfile? activeProfile;
  final List<SpeakerProfile> enrolledProfiles;
  final SpeakerVerificationErrorCategory errorCategory;
  final String? errorMessage;

  SpeakerVerificationState copyWith({
    SpeakerVerificationStatus? status,
    String? activeSessionId,
    SpeakerVerificationResult? lastResult,
    SpeakerProfile? activeProfile,
    List<SpeakerProfile>? enrolledProfiles,
    SpeakerVerificationErrorCategory? errorCategory,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SpeakerVerificationState(
      status: status ?? this.status,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      lastResult: lastResult ?? this.lastResult,
      activeProfile: activeProfile ?? this.activeProfile,
      enrolledProfiles: enrolledProfiles ?? this.enrolledProfiles,
      errorCategory: clearError ? SpeakerVerificationErrorCategory.none : (errorCategory ?? this.errorCategory),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
