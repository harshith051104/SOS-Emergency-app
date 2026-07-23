/// medical_profile_service.dart
///
/// Dedicated service to manage and cache the user's local medical profile
/// persisted in SharedPreferences.

library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/medical_section.dart';

class MedicalProfileService {
  static const String _storageKey = 'elly_medical_profile';
  MedicalSection? _cachedMedicalProfile;

  /// Loads the cached local profile or seeds the default profile in SharedPreferences.
  Future<MedicalSection> getMedicalProfile() async {
    if (_cachedMedicalProfile != null) {
      return _cachedMedicalProfile!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        _cachedMedicalProfile = _fromJson(map);
        return _cachedMedicalProfile!;
      }
    } catch (e) {
      // SharedPreferences / JSON decoding error, fall back to default
    }

    // Default seed medical profile
    final defaultProfile = const MedicalSection(
      medicalInfo: MedicalInformation(
        bloodGroup: 'O+',
        allergies: ['Penicillin', 'Peanuts'],
        medicalConditions: ['Asthma'],
        currentMedications: ['Albuterol Inhaler'],
      ),
      emergencyInfo: EmergencyInformation(
        emergencyNotes: 'Carries inhaler in backpack. Sensitive to dust/pollen.',
        doctorName: 'Dr. Sharma',
        doctorPhone: '+91 99887 76655',
        insuranceProvider: 'Star Health Insurance',
        insurancePolicyNumber: 'POL-88271A',
        preferredHospital: 'Apollo Hospitals, Jubilee Hills',
      ),
    );

    // Persist default to SharedPreferences
    await saveMedicalProfile(defaultProfile);
    _cachedMedicalProfile = defaultProfile;
    return defaultProfile;
  }

  /// Persists profile changes in SharedPreferences.
  Future<void> saveMedicalProfile(MedicalSection profile) async {
    _cachedMedicalProfile = profile;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_toJson(profile));
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      // Fail silently or log
    }
  }

  // ── JSON Helpers ───────────────────────────────────────────────────────────

  Map<String, dynamic> _toJson(MedicalSection profile) {
    return {
      'medicalInfo': {
        'bloodGroup': profile.medicalInfo.bloodGroup,
        'allergies': profile.medicalInfo.allergies,
        'medicalConditions': profile.medicalInfo.medicalConditions,
        'currentMedications': profile.medicalInfo.currentMedications,
      },
      'emergencyInfo': {
        'emergencyNotes': profile.emergencyInfo.emergencyNotes,
        'doctorName': profile.emergencyInfo.doctorName,
        'doctorPhone': profile.emergencyInfo.doctorPhone,
        'insuranceProvider': profile.emergencyInfo.insuranceProvider,
        'insurancePolicyNumber': profile.emergencyInfo.insurancePolicyNumber,
        'preferredHospital': profile.emergencyInfo.preferredHospital,
      },
    };
  }

  MedicalSection _fromJson(Map<String, dynamic> map) {
    final medInfoMap = map['medicalInfo'] as Map<String, dynamic>;
    final medicalInfo = MedicalInformation(
      bloodGroup: medInfoMap['bloodGroup'] as String,
      allergies: List<String>.from(medInfoMap['allergies'] as List),
      medicalConditions: List<String>.from(medInfoMap['medicalConditions'] as List),
      currentMedications: List<String>.from(medInfoMap['currentMedications'] as List),
    );

    final emergInfoMap = map['emergencyInfo'] as Map<String, dynamic>;
    final emergencyInfo = EmergencyInformation(
      emergencyNotes: emergInfoMap['emergencyNotes'] as String,
      doctorName: emergInfoMap['doctorName'] as String,
      doctorPhone: emergInfoMap['doctorPhone'] as String,
      insuranceProvider: emergInfoMap['insuranceProvider'] as String,
      insurancePolicyNumber: emergInfoMap['insurancePolicyNumber'] as String,
      preferredHospital: emergInfoMap['preferredHospital'] as String,
    );

    return MedicalSection(
      medicalInfo: medicalInfo,
      emergencyInfo: emergencyInfo,
    );
  }
}
