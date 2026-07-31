/// emergency_session_config.dart
///
/// Configuration parameters for Emergency Session execution.

library;

import 'package:flutter/foundation.dart';

@immutable
class EmergencySessionConfig {
  const EmergencySessionConfig({
    this.retryCount = 2,
    this.retryDelayMs = 1000,
    this.maximumExecutionTimeMs = 30000,
    this.allowLocationSharing = true,
    this.allowMedicalProfile = true,
    this.allowPhoneCalls = true,
    this.allowNotifications = true,
    this.allowTimelineRecording = true,
  });

  final int retryCount;
  final int retryDelayMs;
  final int maximumExecutionTimeMs;
  final bool allowLocationSharing;
  final bool allowMedicalProfile;
  final bool allowPhoneCalls;
  final bool allowNotifications;
  final bool allowTimelineRecording;
}
