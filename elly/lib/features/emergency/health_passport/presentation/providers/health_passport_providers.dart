/// health_passport_providers.dart
///
/// Riverpod dependency injection definitions exposing HealthPassportStorageService,
/// HealthPassportRepository, HealthPassportController, EmergencyContext envelope,
/// HealthPassportEncryption boundary, and medical providers.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/emergency_health_profile.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/medical_contact.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/health_validation_result.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/emergency_context.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/health_passport_encryption.dart';
import 'package:elly/features/emergency/health_passport/domain/repositories/health_passport_repository.dart';
import 'package:elly/features/emergency/health_passport/data/services/health_passport_storage_service.dart';
import 'package:elly/features/emergency/health_passport/data/repositories/health_passport_repository_impl.dart';
import 'package:elly/features/emergency/health_passport/presentation/controllers/health_passport_controller.dart';
import 'package:elly/features/emergency/telemetry/presentation/providers/telemetry_providers.dart';
import 'package:elly/features/emergency/sos_circle/presentation/providers/sos_circle_providers.dart';

import 'package:elly/features/emergency/responders/presentation/providers/responder_providers.dart';

final healthPassportEncryptionProvider = Provider<HealthPassportEncryption>((ref) {
  // Use the shared SharedPreferences instance for AES key storage.
  // The key is generated once and persisted; subsequent launches reuse it.
  final prefs = ref.watch(sharedPreferencesProvider);
  return AesHealthEncryption(prefs);
});

final healthPassportStorageProvider = Provider<HealthPassportStorageService>((ref) {
  return HealthPassportStorageService();
});

final healthPassportRepositoryProvider = Provider<HealthPassportRepository>((ref) {
  final storage = ref.watch(healthPassportStorageProvider);
  return HealthPassportRepositoryImpl(storageService: storage);
});

final healthPassportControllerProvider =
    StateNotifierProvider<HealthPassportController, HealthPassportState>((ref) {
  final repository = ref.watch(healthPassportRepositoryProvider);
  return HealthPassportController(repository);
});

final healthProfileProvider = Provider<EmergencyHealthProfile?>((ref) {
  final state = ref.watch(healthPassportControllerProvider);
  return state.passport?.profile;
});

final medicalContactsProvider = Provider<List<MedicalContact>>((ref) {
  final state = ref.watch(healthPassportControllerProvider);
  return state.passport?.medicalContacts ?? const [];
});

final validationProvider = Provider<HealthValidationResult?>((ref) {
  final state = ref.watch(healthPassportControllerProvider);
  return state.validationResult;
});

final emergencyContextProvider = Provider<EmergencyContext>((ref) {
  final passportState = ref.watch(healthPassportControllerProvider);
  final telemetrySession = ref.watch(telemetryControllerProvider);

  return EmergencyContext(
    sessionId: telemetrySession.sessionId,
    dispatchId: 'disp_${DateTime.now().millisecondsSinceEpoch}',
    emergencyType: 'Manual SOS',
    startedAt: telemetrySession.startedAt,
    healthPassport: passportState.passport,
    telemetrySession: telemetrySession,
    sosCircle: ref.watch(sosCircleStateProvider),
  );
});
