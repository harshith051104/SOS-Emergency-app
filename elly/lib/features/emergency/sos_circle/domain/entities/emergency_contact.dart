/// emergency_contact.dart
///
/// Immutable domain model representing an individual emergency contact in the SOS Circle.

library;

import 'package:flutter/foundation.dart';

@immutable
class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.fullName,
    required this.relationship,
    required this.primaryPhone,
    this.secondaryPhone,
    this.email,
    this.avatarPath,
    this.priority = 1,
    this.isPrimaryContact = false,
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fullName;
  final String relationship;
  final String primaryPhone;
  final String? secondaryPhone;
  final String? email;
  final String? avatarPath;
  final int priority;
  final bool isPrimaryContact;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyContact copyWith({
    String? id,
    String? fullName,
    String? relationship,
    String? primaryPhone,
    String? secondaryPhone,
    String? email,
    String? avatarPath,
    int? priority,
    bool? isPrimaryContact,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      relationship: relationship ?? this.relationship,
      primaryPhone: primaryPhone ?? this.primaryPhone,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
      priority: priority ?? this.priority,
      isPrimaryContact: isPrimaryContact ?? this.isPrimaryContact,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'relationship': relationship,
      'primaryPhone': primaryPhone,
      'secondaryPhone': secondaryPhone,
      'email': email,
      'avatarPath': avatarPath,
      'priority': priority,
      'isPrimaryContact': isPrimaryContact,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      relationship: json['relationship'] as String,
      primaryPhone: json['primaryPhone'] as String,
      secondaryPhone: json['secondaryPhone'] as String?,
      email: json['email'] as String?,
      avatarPath: json['avatarPath'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      isPrimaryContact: json['isPrimaryContact'] as bool? ?? false,
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyContact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          primaryPhone == other.primaryPhone &&
          isPrimaryContact == other.isPrimaryContact &&
          isEnabled == other.isEnabled;

  @override
  int get hashCode =>
      id.hashCode ^ fullName.hashCode ^ primaryPhone.hashCode ^ isPrimaryContact.hashCode ^ isEnabled.hashCode;
}
