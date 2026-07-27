/// sos_trigger_config_repository_impl.dart
///
/// Data layer implementation for persisting SOS trigger settings using SharedPreferences.

library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/sos_trigger_config.dart';
import '../../domain/repositories/sos_trigger_config_repository.dart';

class SosTriggerConfigRepositoryImpl implements SosTriggerConfigRepository {
  static const String _keyVoiceEnabled = 'elly_trigger_voice_enabled';
  static const String _keyWakeWordEnabled = 'elly_trigger_wakeword_enabled';
  static const String _keyAutoDetectEnabled = 'elly_trigger_autodetect_enabled';

  @override
  Future<SosTriggerConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final voiceEnabled = prefs.getBool(_keyVoiceEnabled) ?? true;
    final wakeWordEnabled = prefs.getBool(_keyWakeWordEnabled) ?? false;
    final autoDetectEnabled = prefs.getBool(_keyAutoDetectEnabled) ?? false;

    final perm = await checkMicrophonePermission();

    return SosTriggerConfig(
      isVoiceTriggerEnabled: voiceEnabled,
      isWakeWordEnabled: wakeWordEnabled,
      isAutoDetectionEnabled: autoDetectEnabled,
      microphonePermission: perm,
    );
  }

  @override
  Future<void> saveConfig(SosTriggerConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVoiceEnabled, config.isVoiceTriggerEnabled);
    await prefs.setBool(_keyWakeWordEnabled, config.isWakeWordEnabled);
    await prefs.setBool(_keyAutoDetectEnabled, config.isAutoDetectionEnabled);
  }

  @override
  Future<TriggerPermissionStatus> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) return TriggerPermissionStatus.granted;
      if (status.isPermanentlyDenied || status.isDenied) return TriggerPermissionStatus.denied;
      if (status.isRestricted) return TriggerPermissionStatus.restricted;
      return TriggerPermissionStatus.unknown;
    } catch (_) {
      return TriggerPermissionStatus.unknown;
    }
  }
}
