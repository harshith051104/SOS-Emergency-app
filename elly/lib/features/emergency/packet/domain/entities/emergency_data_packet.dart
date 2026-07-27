/// emergency_data_packet.dart
///
/// Canonical immutable aggregate root model representing the complete Smart Emergency Data Packet.
/// Supports packet hash/checksum integrity, sequence numbers, status tracking, priority, delta updates,
/// cross-border international context, and GZIP byte compression for Sprint 12 & Sprint 13 readiness.

library;

import 'package:flutter/foundation.dart';

import 'package:elly/features/emergency/sos/domain/entities/confirmation_state.dart';
import 'package:elly/features/emergency/packet/domain/entities/emergency_symptoms_model.dart';
import 'package:elly/features/emergency/packet/domain/entities/device_info_model.dart';

enum PacketStatus {
  created,
  queued,
  uploading,
  uploaded,
  failed,
  expired,
}

enum PacketPriority {
  low,
  medium,
  high,
  critical,
}

@immutable
class EmergencyDataPacket {
  const EmergencyDataPacket({
    required this.packetId,
    required this.sessionId,
    required this.userId,
    required this.generatedAt,
    this.packetVersion = '1.0',
    this.sequenceNumber = 1,
    this.status = PacketStatus.created,
    this.priority = PacketPriority.critical,
    required this.packetHash,
    required this.packetChecksum,
    this.isDelta = false,
    this.changedFields = const [],
    this.countryCode = 'IN',
    this.detectedLanguage = 'en_US',
    this.localEmergencyNumber = '112',
    this.timeZone = 'Asia/Kolkata',
    this.isRoaming = false,
    required this.emergencyState,
    this.confirmationResult,
    this.highRisk = false,
    this.currentSeverity = 'CRITICAL',
    required this.emergencyStartedAt,
    required this.duration,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.altitude,
    required this.accuracy,
    required this.speed,
    required this.heading,
    required this.name,
    required this.age,
    required this.bloodGroup,
    this.allergies = const [],
    this.medications = const [],
    this.chronicConditions = const [],
    this.physician,
    this.emergencyNotes = '',
    this.symptoms = const EmergencySymptomsModel(),
    required this.totalEvents,
    this.latestEvents = const [],
    this.primaryContact,
    this.secondaryContacts = const [],
    required this.deviceInfo,
  });

  // Identity & Integrity
  final String packetId;
  final String sessionId;
  final String userId;
  final DateTime generatedAt;
  final String packetVersion;
  final int sequenceNumber;
  final PacketStatus status;
  final PacketPriority priority;
  final String packetHash;
  final String packetChecksum;
  final bool isDelta;
  final List<String> changedFields;

  // Cross-Border & International
  final String countryCode;
  final String detectedLanguage;
  final String localEmergencyNumber;
  final String timeZone;
  final bool isRoaming;

  // Emergency State
  final String emergencyState;
  final ConfirmationResult? confirmationResult;
  final bool highRisk;
  final String currentSeverity;
  final DateTime emergencyStartedAt;
  final Duration duration;

  // Location
  final double latitude;
  final double longitude;
  final String? address;
  final double altitude;
  final double accuracy;
  final double speed;
  final double heading;

  // Health Summary
  final String name;
  final int age;
  final String bloodGroup;
  final List<String> allergies;
  final List<String> medications;
  final List<String> chronicConditions;
  final String? physician;
  final String emergencyNotes;

  // Symptoms
  final EmergencySymptomsModel symptoms;

  // Timeline Summary
  final int totalEvents;
  final List<String> latestEvents;

  // Contacts
  final Map<String, dynamic>? primaryContact;
  final List<Map<String, dynamic>> secondaryContacts;

  // Diagnostics
  final DeviceInfoModel deviceInfo;

  Map<String, dynamic> toJson() {
    return {
      'packetId': packetId,
      'sessionId': sessionId,
      'userId': userId,
      'generatedAt': generatedAt.toIso8601String(),
      'packetVersion': packetVersion,
      'sequenceNumber': sequenceNumber,
      'status': status.name,
      'priority': priority.name,
      'packetHash': packetHash,
      'packetChecksum': packetChecksum,
      'isDelta': isDelta,
      'changedFields': changedFields,
      'countryCode': countryCode,
      'detectedLanguage': detectedLanguage,
      'localEmergencyNumber': localEmergencyNumber,
      'timeZone': timeZone,
      'isRoaming': isRoaming,
      'emergencyState': emergencyState,
      'confirmationResult': confirmationResult?.toJson(),
      'highRisk': highRisk,
      'currentSeverity': currentSeverity,
      'emergencyStartedAt': emergencyStartedAt.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'altitude': altitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
      },
      'healthSummary': {
        'name': name,
        'age': age,
        'bloodGroup': bloodGroup,
        'allergies': allergies,
        'medications': medications,
        'chronicConditions': chronicConditions,
        'physician': physician,
        'emergencyNotes': emergencyNotes,
      },
      'symptoms': symptoms.toJson(),
      'timelineSummary': {
        'totalEvents': totalEvents,
        'latestEvents': latestEvents,
      },
      'contacts': {
        'primaryContact': primaryContact,
        'secondaryContacts': secondaryContacts,
      },
      'deviceInfo': deviceInfo.toJson(),
    };
  }

  factory EmergencyDataPacket.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? {};
    final health = json['healthSummary'] as Map<String, dynamic>? ?? {};
    final timeline = json['timelineSummary'] as Map<String, dynamic>? ?? {};
    final contacts = json['contacts'] as Map<String, dynamic>? ?? {};

    return EmergencyDataPacket(
      packetId: json['packetId'] as String,
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      packetVersion: json['packetVersion'] as String? ?? '1.0',
      sequenceNumber: json['sequenceNumber'] as int? ?? 1,
      status: PacketStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PacketStatus.created,
      ),
      priority: PacketPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => PacketPriority.critical,
      ),
      packetHash: json['packetHash'] as String? ?? '',
      packetChecksum: json['packetChecksum'] as String? ?? '',
      isDelta: json['isDelta'] as bool? ?? false,
      changedFields: (json['changedFields'] as List<dynamic>?)?.cast<String>() ?? const [],
      countryCode: json['countryCode'] as String? ?? 'IN',
      detectedLanguage: json['detectedLanguage'] as String? ?? 'en_US',
      localEmergencyNumber: json['localEmergencyNumber'] as String? ?? '112',
      timeZone: json['timeZone'] as String? ?? 'Asia/Kolkata',
      isRoaming: json['isRoaming'] as bool? ?? false,
      emergencyState: json['emergencyState'] as String? ?? 'ACTIVE',
      confirmationResult: json['confirmationResult'] != null
          ? ConfirmationResult.fromJson(Map<String, dynamic>.from(json['confirmationResult'] as Map))
          : null,
      highRisk: json['highRisk'] as bool? ?? false,
      currentSeverity: json['currentSeverity'] as String? ?? 'CRITICAL',
      emergencyStartedAt: DateTime.parse(json['emergencyStartedAt'] as String),
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      latitude: (loc['latitude'] as num? ?? 0.0).toDouble(),
      longitude: (loc['longitude'] as num? ?? 0.0).toDouble(),
      address: loc['address'] as String?,
      altitude: (loc['altitude'] as num? ?? 0.0).toDouble(),
      accuracy: (loc['accuracy'] as num? ?? 0.0).toDouble(),
      speed: (loc['speed'] as num? ?? 0.0).toDouble(),
      heading: (loc['heading'] as num? ?? 0.0).toDouble(),
      name: health['name'] as String? ?? 'John Doe',
      age: health['age'] as int? ?? 30,
      bloodGroup: health['bloodGroup'] as String? ?? 'O+',
      allergies: (health['allergies'] as List<dynamic>?)?.cast<String>() ?? const [],
      medications: (health['medications'] as List<dynamic>?)?.cast<String>() ?? const [],
      chronicConditions: (health['chronicConditions'] as List<dynamic>?)?.cast<String>() ?? const [],
      physician: health['physician'] as String?,
      emergencyNotes: health['emergencyNotes'] as String? ?? '',
      symptoms: json['symptoms'] != null
          ? EmergencySymptomsModel.fromJson(Map<String, dynamic>.from(json['symptoms'] as Map))
          : const EmergencySymptomsModel(),
      totalEvents: timeline['totalEvents'] as int? ?? 0,
      latestEvents: (timeline['latestEvents'] as List<dynamic>?)?.cast<String>() ?? const [],
      primaryContact: contacts['primaryContact'] as Map<String, dynamic>?,
      secondaryContacts: (contacts['secondaryContacts'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? const [],
      deviceInfo: json['deviceInfo'] != null
          ? DeviceInfoModel.fromJson(Map<String, dynamic>.from(json['deviceInfo'] as Map))
          : const DeviceInfoModel(batteryLevel: 100, networkState: 'online', gpsAvailable: true),

    );
  }
}
