/// sos_trigger_config.dart
///
/// Domain entity representing local user configuration and permission status
/// for emergency trigger methods and anti-false confirmation settings.

library;

enum TriggerPermissionStatus { granted, denied, restricted, unknown }

class SosTriggerConfig {
  const SosTriggerConfig({
    this.isManualEnabled = true, // Always true & locked
    this.isVoiceTriggerEnabled = true,
    this.isWakeWordEnabled = false,
    this.isAutoDetectionEnabled = false,
    this.microphonePermission = TriggerPermissionStatus.unknown,
    this.isConfirmationEnabled = true,
    this.confirmationDurationSeconds = 7,
    this.isVoiceConfirmationEnabled = true,
    this.autoTriggerOnTimeout = true,
    this.skipConfirmationForHighRisk = true,
  });

  final bool isManualEnabled;
  final bool isVoiceTriggerEnabled;
  final bool isWakeWordEnabled;
  final bool isAutoDetectionEnabled;
  final TriggerPermissionStatus microphonePermission;
  final bool isConfirmationEnabled;
  final int confirmationDurationSeconds;
  final bool isVoiceConfirmationEnabled;
  final bool autoTriggerOnTimeout;
  final bool skipConfirmationForHighRisk;

  SosTriggerConfig copyWith({
    bool? isManualEnabled,
    bool? isVoiceTriggerEnabled,
    bool? isWakeWordEnabled,
    bool? isAutoDetectionEnabled,
    TriggerPermissionStatus? microphonePermission,
    bool? isConfirmationEnabled,
    int? confirmationDurationSeconds,
    bool? isVoiceConfirmationEnabled,
    bool? autoTriggerOnTimeout,
    bool? skipConfirmationForHighRisk,
  }) {
    return SosTriggerConfig(
      isVoiceTriggerEnabled: isVoiceTriggerEnabled ?? this.isVoiceTriggerEnabled,
      isWakeWordEnabled: isWakeWordEnabled ?? this.isWakeWordEnabled,
      isAutoDetectionEnabled: isAutoDetectionEnabled ?? this.isAutoDetectionEnabled,
      microphonePermission: microphonePermission ?? this.microphonePermission,
      isConfirmationEnabled: isConfirmationEnabled ?? this.isConfirmationEnabled,
      confirmationDurationSeconds: confirmationDurationSeconds ?? this.confirmationDurationSeconds,
      isVoiceConfirmationEnabled: isVoiceConfirmationEnabled ?? this.isVoiceConfirmationEnabled,
      autoTriggerOnTimeout: autoTriggerOnTimeout ?? this.autoTriggerOnTimeout,
      skipConfirmationForHighRisk: skipConfirmationForHighRisk ?? this.skipConfirmationForHighRisk,
    );
  }
}
