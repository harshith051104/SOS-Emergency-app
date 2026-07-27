/// sos_trigger_config_provider.dart
///
/// Riverpod StateNotifier managing the single source of truth for SOS trigger settings.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/sos_trigger_config.dart';
import '../../domain/repositories/sos_trigger_config_repository.dart';
import '../../data/repositories/sos_trigger_config_repository_impl.dart';

final sosTriggerConfigRepositoryProvider = Provider<SosTriggerConfigRepository>((ref) {
  return SosTriggerConfigRepositoryImpl();
});

final sosTriggerConfigProvider =
    StateNotifierProvider<SosTriggerConfigNotifier, SosTriggerConfig>((ref) {
  final repo = ref.watch(sosTriggerConfigRepositoryProvider);
  return SosTriggerConfigNotifier(repo);
});

class SosTriggerConfigNotifier extends StateNotifier<SosTriggerConfig> {
  SosTriggerConfigNotifier(this._repository) : super(const SosTriggerConfig()) {
    _loadInitialConfig();
  }

  final SosTriggerConfigRepository _repository;

  Future<void> _loadInitialConfig() async {
    final loaded = await _repository.loadConfig();
    state = loaded;
  }

  Future<void> toggleVoiceTrigger(bool enabled) async {
    state = state.copyWith(isVoiceTriggerEnabled: enabled);
    await _repository.saveConfig(state);
  }

  Future<void> toggleWakeWord(bool enabled) async {
    state = state.copyWith(isWakeWordEnabled: enabled);
    await _repository.saveConfig(state);
  }

  Future<void> toggleAutoDetection(bool enabled) async {
    state = state.copyWith(isAutoDetectionEnabled: enabled);
    await _repository.saveConfig(state);
  }

  Future<void> refreshPermissions() async {
    final perm = await _repository.checkMicrophonePermission();
    state = state.copyWith(microphonePermission: perm);
  }

  Future<void> openSystemSettings() async {
    await openAppSettings();
    await refreshPermissions();
  }
}
