/// health_passport_repository.dart
///
/// Abstract domain repository contract for Health Passport persistence and state observation.

library;

import 'package:elly/features/emergency/health_passport/domain/entities/health_passport.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/emergency_health_profile.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/health_validation_result.dart';

abstract class HealthPassportRepository {
  Future<HealthPassport> loadProfile();
  Future<void> saveProfile(HealthPassport passport);
  Future<void> updateProfile(EmergencyHealthProfile profile);
  Future<void> deleteProfile();
  HealthValidationResult validateProfile(HealthPassport passport);
  Stream<HealthPassport> watchProfile();
}
