/// medical_section.dart
///
/// Part of the versioned Emergency Data Packet.
/// Contains distinct structures for medical indicators and emergency contact profile data.

library;

import 'package:equatable/equatable.dart';

class MedicalInformation extends Equatable {
  const MedicalInformation({
    required this.bloodGroup,
    required this.allergies,
    required this.medicalConditions,
    required this.currentMedications,
  });

  final String bloodGroup;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> currentMedications;

  MedicalInformation copyWith({
    String? bloodGroup,
    List<String>? allergies,
    List<String>? medicalConditions,
    List<String>? currentMedications,
  }) {
    return MedicalInformation(
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      currentMedications: currentMedications ?? this.currentMedications,
    );
  }

  @override
  List<Object?> get props => [
        bloodGroup,
        allergies,
        medicalConditions,
        currentMedications,
      ];
}

class EmergencyInformation extends Equatable {
  const EmergencyInformation({
    required this.emergencyNotes,
    required this.doctorName,
    required this.doctorPhone,
    required this.insuranceProvider,
    required this.insurancePolicyNumber,
    required this.preferredHospital,
  });

  final String emergencyNotes;
  final String doctorName;
  final String doctorPhone;
  final String insuranceProvider;
  final String insurancePolicyNumber;
  final String preferredHospital;

  EmergencyInformation copyWith({
    String? emergencyNotes,
    String? doctorName,
    String? doctorPhone,
    String? insuranceProvider,
    String? insurancePolicyNumber,
    String? preferredHospital,
  }) {
    return EmergencyInformation(
      emergencyNotes: emergencyNotes ?? this.emergencyNotes,
      doctorName: doctorName ?? this.doctorName,
      doctorPhone: doctorPhone ?? this.doctorPhone,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insurancePolicyNumber: insurancePolicyNumber ?? this.insurancePolicyNumber,
      preferredHospital: preferredHospital ?? this.preferredHospital,
    );
  }

  @override
  List<Object?> get props => [
        emergencyNotes,
        doctorName,
        doctorPhone,
        insuranceProvider,
        insurancePolicyNumber,
        preferredHospital,
      ];
}

class MedicalSection extends Equatable {
  const MedicalSection({
    required this.medicalInfo,
    required this.emergencyInfo,
  });

  final MedicalInformation medicalInfo;
  final EmergencyInformation emergencyInfo;

  MedicalSection copyWith({
    MedicalInformation? medicalInfo,
    EmergencyInformation? emergencyInfo,
  }) {
    return MedicalSection(
      medicalInfo: medicalInfo ?? this.medicalInfo,
      emergencyInfo: emergencyInfo ?? this.emergencyInfo,
    );
  }

  @override
  List<Object?> get props => [
        medicalInfo,
        emergencyInfo,
      ];
}
