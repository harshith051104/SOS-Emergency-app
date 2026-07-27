/// health_passport_validator.dart
///
/// Pure domain validator for Health Passport calculating profile completeness score %,
/// validating blood group formats, phone/email syntax, and detecting duplicate physicians.

library;

import 'package:elly/features/emergency/health_passport/domain/entities/health_passport.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/health_validation_result.dart';

class HealthPassportValidator {
  static const Set<String> validBloodGroups = {
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'UNKNOWN'
  };

  static final RegExp phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,20}$');
  static final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  /// Calculates profile completeness score (0 - 100%) and returns validation report.
  static HealthValidationResult validate(HealthPassport passport) {
    final profile = passport.profile;
    final missing = <String>[];
    final warnings = <String>[];
    int score = 0;

    // 1. Full Name (+15%)
    if (profile.fullName.trim().isNotEmpty) {
      score += 15;
    } else {
      missing.add('Full Name is required');
    }

    // 2. Blood Group (+20%)
    final bg = profile.bloodGroup.toUpperCase().trim();
    if (bg.isNotEmpty && bg != 'UNKNOWN') {
      if (validBloodGroups.contains(bg)) {
        score += 20;
      } else {
        warnings.add('Invalid blood group format: $bg. Expected A+, A-, B+, B-, AB+, AB-, O+, O-');
      }
    } else {
      missing.add('Blood Group is unspecified');
    }

    // 3. Emergency Notes (+15%)
    if (profile.emergencyNotes.trim().isNotEmpty) {
      score += 15;
    } else {
      missing.add('Emergency Notes are empty');
    }

    // 4. Allergies (+15%)
    if (profile.allergies.isNotEmpty) {
      score += 15;
    } else {
      warnings.add('No allergies listed. If none, specify "No Known Allergies (NKDA)"');
    }

    // 5. Medications (+15%)
    if (profile.medications.isNotEmpty) {
      score += 15;
    }

    // 6. Chronic Conditions (+10%)
    if (profile.chronicConditions.isNotEmpty) {
      score += 10;
    }

    // 7. Physician Information (+10%)
    if (profile.physicianName != null && profile.physicianName!.trim().isNotEmpty) {
      score += 10;
      if (profile.physicianPhone != null && !phoneRegex.hasMatch(profile.physicianPhone!.trim())) {
        warnings.add('Invalid primary physician phone format: ${profile.physicianPhone}');
      }
    }

    // Check duplicate physicians in MedicalContacts list
    final physicianNames = <String>{};
    for (final contact in passport.medicalContacts) {
      final nameLower = contact.physicianName.trim().toLowerCase();
      if (physicianNames.contains(nameLower)) {
        warnings.add('Duplicate medical contact found for physician: ${contact.physicianName}');
      } else {
        physicianNames.add(nameLower);
      }

      if (!phoneRegex.hasMatch(contact.phone.trim())) {
        warnings.add('Invalid phone number for medical contact ${contact.physicianName}: ${contact.phone}');
      }

      if (contact.email != null && contact.email!.isNotEmpty && !emailRegex.hasMatch(contact.email!.trim())) {
        warnings.add('Invalid email format for medical contact ${contact.physicianName}: ${contact.email}');
      }
    }

    if (missing.isEmpty && warnings.isEmpty) {
      return HealthValidationResult.valid(score, warnings);
    } else {
      return HealthValidationResult.invalid(
        missingFields: missing,
        warnings: warnings,
        score: score,
      );
    }
  }
}
