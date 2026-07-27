/// health_passport_repository_impl.dart
///
/// Data layer implementation of HealthPassportRepository managing storage, domain mapping,
/// default seeding, and streaming profile updates.

library;

import 'dart:async';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/health_passport.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/emergency_health_profile.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/medical_contact.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/health_validation_result.dart';
import 'package:elly/features/emergency/health_passport/domain/validation/health_passport_validator.dart';
import 'package:elly/features/emergency/health_passport/domain/repositories/health_passport_repository.dart';
import 'package:elly/features/emergency/health_passport/data/services/health_passport_storage_service.dart';

class HealthPassportRepositoryImpl implements HealthPassportRepository {
  HealthPassportRepositoryImpl({HealthPassportStorageService? storageService})
      : _storage = storageService ?? HealthPassportStorageService(),
        _streamController = StreamController<HealthPassport>.broadcast();

  final HealthPassportStorageService _storage;
  final StreamController<HealthPassport> _streamController;
  HealthPassport? _cachedPassport;

  @override
  Future<HealthPassport> loadProfile() async {
    if (_cachedPassport != null) return _cachedPassport!;

    final jsonMap = await _storage.readPassportJson();
    if (jsonMap != null) {
      try {
        final passport = HealthPassport.fromJson(jsonMap);
        _cachedPassport = passport;
        appLogger.info('HealthPassportRepositoryImpl: Successfully loaded profile for ${passport.profile.fullName}');
        return passport;
      } catch (e, st) {
        appLogger.error('HealthPassportRepositoryImpl: Error parsing JSON, falling back to seed', e, st);
      }
    }

    final defaultPassport = _generateDefaultSeedPassport();
    final validation = validateProfile(defaultPassport);
    final validatedPassport = defaultPassport.copyWith(completenessScore: validation.completenessScore);

    await saveProfile(validatedPassport);
    _cachedPassport = validatedPassport;
    return validatedPassport;
  }

  @override
  Future<void> saveProfile(HealthPassport passport) async {
    final validation = validateProfile(passport);
    final updated = passport.copyWith(
      lastUpdated: DateTime.now(),
      completenessScore: validation.completenessScore,
    );

    _cachedPassport = updated;
    await _storage.writePassportJson(updated.toJson());
    if (!_streamController.isClosed) {
      _streamController.add(updated);
    }
    appLogger.info('HealthPassportRepositoryImpl: Saved profile (Completeness: ${updated.completenessScore}%)');
  }

  @override
  Future<void> updateProfile(EmergencyHealthProfile profile) async {
    final current = await loadProfile();
    final updatedPassport = current.copyWith(
      profile: profile.copyWith(updatedAt: DateTime.now()),
    );
    await saveProfile(updatedPassport);
  }

  @override
  Future<void> deleteProfile() async {
    await _storage.deletePassportJson();
    _cachedPassport = _generateDefaultSeedPassport();
    if (!_streamController.isClosed) {
      _streamController.add(_cachedPassport!);
    }
    appLogger.info('HealthPassportRepositoryImpl: Reset profile to default seed.');
  }

  @override
  HealthValidationResult validateProfile(HealthPassport passport) {
    return HealthPassportValidator.validate(passport);
  }

  @override
  Stream<HealthPassport> watchProfile() => _streamController.stream;

  HealthPassport _generateDefaultSeedPassport() {
    final now = DateTime.now();
    final profile = EmergencyHealthProfile(
      profileId: 'prof_default_01',
      fullName: 'Alex Vance',
      bloodGroup: 'O+',
      age: 29,
      gender: 'Male',
      heightCm: 178.0,
      weightKg: 74.0,
      allergies: const ['Penicillin', 'Peanuts'],
      medications: const ['Albuterol Inhaler (PRN)'],
      chronicConditions: const ['Asthma (Mild)'],
      emergencyNotes: 'Carries EpiPen in backpack side pocket. Severe peanut allergy.',

      organDonor: true,
      insuranceProvider: 'BlueShield Emergency Protection',
      insuranceNumber: 'BS-9948201-X',
      physicianName: 'Dr. Sarah Smith',
      physicianPhone: '+1 800-555-0188',
      createdAt: now,
      updatedAt: now,
    );

    final contacts = [
      const MedicalContact(
        id: 'med_01',
        hospitalName: 'St. Jude Emergency Medical Center',
        physicianName: 'Dr. Sarah Smith',
        phone: '+1 800-555-0188',
        email: 'dr.smith@stjude-health.org',
        address: '742 Evergreen Terrace, Medical District',
        specialty: 'Primary Care & Emergency Triage',
      ),
    ];

    return HealthPassport(
      profile: profile,
      medicalContacts: contacts,
      lastUpdated: now,
      completenessScore: 90,
    );
  }
}
