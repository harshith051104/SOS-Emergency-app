/// sos_trigger_config_repository.dart
///
/// Abstract repository interface for persisting and loading SOS trigger configurations.

library;

import '../entities/sos_trigger_config.dart';

abstract interface class SosTriggerConfigRepository {
  Future<SosTriggerConfig> loadConfig();
  Future<void> saveConfig(SosTriggerConfig config);
  Future<TriggerPermissionStatus> checkMicrophonePermission();
}
