/// health_passport_controller.dart
///
/// Controller managing presentation state for Emergency Health Passport profile & medical contacts.

library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/health_passport.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/emergency_health_profile.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/medical_contact.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/health_validation_result.dart';
import 'package:elly/features/emergency/health_passport/domain/repositories/health_passport_repository.dart';

@immutable
class HealthPassportState {
  const HealthPassportState({
    this.passport,
    this.isLoading = false,
    this.validationResult,
    this.errorMessage,
  });

  final HealthPassport? passport;
  final bool isLoading;
  final HealthValidationResult? validationResult;
  final String? errorMessage;

  HealthPassportState copyWith({
    HealthPassport? passport,
    bool? isLoading,
    HealthValidationResult? validationResult,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HealthPassportState(
      passport: passport ?? this.passport,
      isLoading: isLoading ?? this.isLoading,
      validationResult: validationResult ?? this.validationResult,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class HealthPassportController extends StateNotifier<HealthPassportState> {
  HealthPassportController(this._repository) : super(const HealthPassportState()) {
    loadProfile();
  }

  final HealthPassportRepository _repository;

  /// Loads the profile from repository into presentation state.
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final passport = await _repository.loadProfile();
      final validation = _repository.validateProfile(passport);
      state = state.copyWith(
        passport: passport,
        validationResult: validation,
        isLoading: false,
      );
      appLogger.info('HealthPassportController: Successfully loaded profile (Completeness: ${passport.completenessScore}%)');
    } catch (e, st) {
      appLogger.error('HealthPassportController: Error loading profile', e, st);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Updates personal medical profile.
  Future<bool> updateProfile(EmergencyHealthProfile updatedProfile) async {
    if (state.passport == null) return false;
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await _repository.updateProfile(updatedProfile);
      final refreshed = await _repository.loadProfile();
      final validation = _repository.validateProfile(refreshed);

      state = state.copyWith(
        passport: refreshed,
        validationResult: validation,
        isLoading: false,
      );
      appLogger.info('HealthPassportController: Successfully updated profile.');
      return true;
    } catch (e, st) {
      appLogger.error('HealthPassportController: Error updating profile', e, st);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Adds a new MedicalContact.
  Future<bool> addMedicalContact(MedicalContact contact) async {
    if (state.passport == null) return false;
    try {
      final currentContacts = List<MedicalContact>.from(state.passport!.medicalContacts)..add(contact);
      final updatedPassport = state.passport!.copyWith(medicalContacts: currentContacts);

      await _repository.saveProfile(updatedPassport);
      final refreshed = await _repository.loadProfile();
      final validation = _repository.validateProfile(refreshed);

      state = state.copyWith(
        passport: refreshed,
        validationResult: validation,
      );
      return true;
    } catch (e, st) {
      appLogger.error('HealthPassportController: Error adding medical contact', e, st);
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Deletes a MedicalContact by ID.
  Future<bool> deleteMedicalContact(String contactId) async {
    if (state.passport == null) return false;
    try {
      final currentContacts = state.passport!.medicalContacts.where((c) => c.id != contactId).toList();
      final updatedPassport = state.passport!.copyWith(medicalContacts: currentContacts);

      await _repository.saveProfile(updatedPassport);
      final refreshed = await _repository.loadProfile();
      final validation = _repository.validateProfile(refreshed);

      state = state.copyWith(
        passport: refreshed,
        validationResult: validation,
      );
      return true;
    } catch (e, st) {
      appLogger.error('HealthPassportController: Error deleting medical contact', e, st);
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}
