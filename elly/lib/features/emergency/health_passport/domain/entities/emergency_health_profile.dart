/// emergency_health_profile.dart
///
/// Immutable domain model representing personal medical profile demographics,
/// blood group, allergies, medications, donor status, physician contact details,
/// data severity classification, and schema versioning.

library;

import 'package:flutter/foundation.dart';

enum HealthFieldSeverity {
  critical, // Blood Group, Allergies, Chronic Conditions
  important, // Medications, Primary Physician Info
  optional,  // Insurance, Organ Donor Status
}

@immutable
class EmergencyHealthProfile {
  const EmergencyHealthProfile({
    required this.profileId,
    required this.fullName,
    required this.bloodGroup,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    this.allergies = const [],
    this.medications = const [],
    this.chronicConditions = const [],
    this.disabilities = const [],
    this.emergencyNotes = '',
    this.organDonor = false,
    this.insuranceProvider,
    this.insuranceNumber,
    this.physicianName,
    this.physicianPhone,
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = 1,
  });

  final String profileId;
  final String fullName;
  final String bloodGroup;
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final List<String> allergies;
  final List<String> medications;
  final List<String> chronicConditions;
  final List<String> disabilities;
  final String emergencyNotes;
  final bool organDonor;
  final String? insuranceProvider;
  final String? insuranceNumber;
  final String? physicianName;
  final String? physicianPhone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int schemaVersion;

  Map<String, String> get criticalSummary => {
        'Blood Group': bloodGroup,
        'Allergies': allergies.isNotEmpty ? allergies.join(', ') : 'NKDA',
        'Chronic Conditions': chronicConditions.isNotEmpty ? chronicConditions.join(', ') : 'None',
      };

  Map<String, String> get importantSummary => {
        'Medications': medications.isNotEmpty ? medications.join(', ') : 'None',
        'Physician': physicianName != null ? '$physicianName ($physicianPhone)' : 'N/A',
      };

  EmergencyHealthProfile copyWith({
    String? profileId,
    String? fullName,
    String? bloodGroup,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    List<String>? allergies,
    List<String>? medications,
    List<String>? chronicConditions,
    List<String>? disabilities,
    String? emergencyNotes,
    bool? organDonor,
    String? insuranceProvider,
    String? insuranceNumber,
    String? physicianName,
    String? physicianPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? schemaVersion,
  }) {
    return EmergencyHealthProfile(
      profileId: profileId ?? this.profileId,
      fullName: fullName ?? this.fullName,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      disabilities: disabilities ?? this.disabilities,
      emergencyNotes: emergencyNotes ?? this.emergencyNotes,
      organDonor: organDonor ?? this.organDonor,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      physicianName: physicianName ?? this.physicianName,
      physicianPhone: physicianPhone ?? this.physicianPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      'fullName': fullName,
      'bloodGroup': bloodGroup,
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'allergies': allergies,
      'medications': medications,
      'chronicConditions': chronicConditions,
      'disabilities': disabilities,
      'emergencyNotes': emergencyNotes,
      'organDonor': organDonor,
      'insuranceProvider': insuranceProvider,
      'insuranceNumber': insuranceNumber,
      'physicianName': physicianName,
      'physicianPhone': physicianPhone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'schemaVersion': schemaVersion,
    };
  }

  factory EmergencyHealthProfile.fromJson(Map<String, dynamic> json) {
    return EmergencyHealthProfile(
      profileId: json['profileId'] as String,
      fullName: json['fullName'] as String,
      bloodGroup: json['bloodGroup'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      heightCm: (json['heightCm'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      allergies: List<String>.from(json['allergies'] as List? ?? []),
      medications: List<String>.from(json['medications'] as List? ?? []),
      chronicConditions: List<String>.from(json['chronicConditions'] as List? ?? []),
      disabilities: List<String>.from(json['disabilities'] as List? ?? []),
      emergencyNotes: (json['emergencyNotes'] as String?) ?? '',
      organDonor: (json['organDonor'] as bool?) ?? false,
      insuranceProvider: json['insuranceProvider'] as String?,
      insuranceNumber: json['insuranceNumber'] as String?,
      physicianName: json['physicianName'] as String?,
      physicianPhone: json['physicianPhone'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      schemaVersion: (json['schemaVersion'] as int?) ?? 1,
    );
  }
}
