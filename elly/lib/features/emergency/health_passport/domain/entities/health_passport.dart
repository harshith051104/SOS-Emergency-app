/// health_passport.dart
///
/// Aggregate root domain entity for Emergency Health Passport with schema versioning.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/emergency_health_profile.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/medical_contact.dart';

@immutable
class HealthPassport {
  const HealthPassport({
    required this.profile,
    this.medicalContacts = const [],
    required this.lastUpdated,
    required this.completenessScore,
    this.schemaVersion = 1,
  });

  final EmergencyHealthProfile profile;
  final List<MedicalContact> medicalContacts;
  final DateTime lastUpdated;
  final int completenessScore;
  final int schemaVersion;

  HealthPassport copyWith({
    EmergencyHealthProfile? profile,
    List<MedicalContact>? medicalContacts,
    DateTime? lastUpdated,
    int? completenessScore,
    int? schemaVersion,
  }) {
    return HealthPassport(
      profile: profile ?? this.profile,
      medicalContacts: medicalContacts ?? this.medicalContacts,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      completenessScore: completenessScore ?? this.completenessScore,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'medicalContacts': medicalContacts.map((c) => c.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'completenessScore': completenessScore,
      'schemaVersion': schemaVersion,
    };
  }

  factory HealthPassport.fromJson(Map<String, dynamic> json) {
    return HealthPassport(
      profile: EmergencyHealthProfile.fromJson(json['profile'] as Map<String, dynamic>),
      medicalContacts: (json['medicalContacts'] as List? ?? [])
          .map((c) => MedicalContact.fromJson(c as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      completenessScore: json['completenessScore'] as int,
      schemaVersion: (json['schemaVersion'] as int?) ?? 1,
    );
  }
}
