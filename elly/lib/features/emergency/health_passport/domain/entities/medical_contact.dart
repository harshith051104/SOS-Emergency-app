/// medical_contact.dart
///
/// Immutable domain model representing a hospital, physician, or specialty medical contact.

library;

import 'package:flutter/foundation.dart';

@immutable
class MedicalContact {
  const MedicalContact({
    required this.id,
    required this.hospitalName,
    required this.physicianName,
    required this.phone,
    this.email,
    this.address,
    required this.specialty,
  });

  final String id;
  final String hospitalName;
  final String physicianName;
  final String phone;
  final String? email;
  final String? address;
  final String specialty;

  MedicalContact copyWith({
    String? id,
    String? hospitalName,
    String? physicianName,
    String? phone,
    String? email,
    String? address,
    String? specialty,
  }) {
    return MedicalContact(
      id: id ?? this.id,
      hospitalName: hospitalName ?? this.hospitalName,
      physicianName: physicianName ?? this.physicianName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      specialty: specialty ?? this.specialty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hospitalName': hospitalName,
      'physicianName': physicianName,
      'phone': phone,
      'email': email,
      'address': address,
      'specialty': specialty,
    };
  }

  factory MedicalContact.fromJson(Map<String, dynamic> json) {
    return MedicalContact(
      id: json['id'] as String,
      hospitalName: json['hospitalName'] as String,
      physicianName: json['physicianName'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      specialty: json['specialty'] as String,
    );
  }
}
