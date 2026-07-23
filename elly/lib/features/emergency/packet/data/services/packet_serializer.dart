/// packet_serializer.dart
///
/// Serializes EmergencyPacket to JSON and deserializes it back.
/// Prepares structural architecture for future cryptographic payload encryption.

library;

import 'dart:convert';
import '../../domain/entities/device_section.dart';
import '../../domain/entities/emergency_packet.dart';
import '../../domain/entities/location_section.dart';
import '../../domain/entities/medical_section.dart';
import '../../domain/entities/packet_metadata.dart';
import '../../domain/entities/responder_section.dart';
import '../../domain/entities/timeline_section.dart';

class EmergencyPacketSerializer {
  const EmergencyPacketSerializer();

  /// Converts the EmergencyPacket into a standard JSON string.
  String serialize(EmergencyPacket packet) {
    final map = <String, dynamic>{
      'id': packet.id,
      'sessionId': packet.sessionId,
      'version': packet.version,
      'type': packet.type,
      'status': packet.status,
      'startedAt': packet.startedAt.toIso8601String(),
      'currentTime': packet.currentTime.toIso8601String(),
      'durationMs': packet.duration.inMilliseconds,
      'metadata': {
        'created': packet.metadata.created.toIso8601String(),
        'updated': packet.metadata.updated.toIso8601String(),
        'version': packet.metadata.version,
        'generatedBy': packet.metadata.generatedBy,
        'packetSize': packet.metadata.packetSize,
        'checksum': packet.metadata.checksum,
      },
      'location': {
        'latitude': packet.location.latitude,
        'longitude': packet.location.longitude,
        'address': packet.location.address,
        'accuracy': packet.location.accuracy,
        'timestamp': packet.location.timestamp.toIso8601String(),
        'permissionStatus': packet.location.permissionStatus,
        'isGpsEnabled': packet.location.isGpsEnabled,
        'isMockLocation': packet.location.isMockLocation,
      },
      'device': {
        'batteryPercent': packet.device.batteryPercent,
        'isCharging': packet.device.isCharging,
        'connectionType': packet.device.connectionType,
        'isInternetAvailable': packet.device.isInternetAvailable,
        'platform': packet.device.platform,
        'deviceName': packet.device.deviceName,
        'osVersion': packet.device.osVersion,
        'isScreenLocked': packet.device.isScreenLocked,
        'isBatterySaverEnabled': packet.device.isBatterySaverEnabled,
        'isLowPowerMode': packet.device.isLowPowerMode,
        'timeZone': packet.device.timeZone,
        'locale': packet.device.locale,
      },
      'medical': {
        'medicalInfo': {
          'bloodGroup': packet.medical.medicalInfo.bloodGroup,
          'allergies': packet.medical.medicalInfo.allergies,
          'medicalConditions': packet.medical.medicalInfo.medicalConditions,
          'currentMedications': packet.medical.medicalInfo.currentMedications,
        },
        'emergencyInfo': {
          'emergencyNotes': packet.medical.emergencyInfo.emergencyNotes,
          'doctorName': packet.medical.emergencyInfo.doctorName,
          'doctorPhone': packet.medical.emergencyInfo.doctorPhone,
          'insuranceProvider': packet.medical.emergencyInfo.insuranceProvider,
          'insurancePolicyNumber': packet.medical.emergencyInfo.insurancePolicyNumber,
          'preferredHospital': packet.medical.emergencyInfo.preferredHospital,
        },
      },
      'responders': packet.responders.responders.map((r) {
        return {
          'id': r.id,
          'name': r.name,
          'relationship': r.relationship,
          'phone': r.phone,
          'notificationStatus': r.notificationStatus.name,
          'isAcknowledged': r.isAcknowledged,
          'acknowledgedTime': r.acknowledgedTime?.toIso8601String(),
        };
      }).toList(),
      'timeline': packet.timeline.events.map((e) {
        return {
          'id': e.id,
          'title': e.title,
          'timestamp': e.timestamp.toIso8601String(),
          'description': e.description,
        };
      }).toList(),
    };

    return jsonEncode(map);
  }

  /// Reconstructs the EmergencyPacket from a JSON string.
  EmergencyPacket deserialize(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;

    final metadataMap = map['metadata'] as Map<String, dynamic>;
    final metadata = PacketMetadata(
      created: DateTime.parse(metadataMap['created'] as String),
      updated: DateTime.parse(metadataMap['updated'] as String),
      version: metadataMap['version'] as int,
      generatedBy: metadataMap['generatedBy'] as String,
      packetSize: metadataMap['packetSize'] as String,
      checksum: metadataMap['checksum'] as String,
    );

    final locMap = map['location'] as Map<String, dynamic>;
    final location = LocationSection(
      latitude: locMap['latitude'] as double?,
      longitude: locMap['longitude'] as double?,
      address: locMap['address'] as String,
      accuracy: locMap['accuracy'] as String,
      timestamp: DateTime.parse(locMap['timestamp'] as String),
      permissionStatus: locMap['permissionStatus'] as String,
      isGpsEnabled: locMap['isGpsEnabled'] as bool,
      isMockLocation: locMap['isMockLocation'] as bool,
    );

    final devMap = map['device'] as Map<String, dynamic>;
    final device = DeviceSection(
      batteryPercent: devMap['batteryPercent'] as int,
      isCharging: devMap['isCharging'] as bool,
      connectionType: devMap['connectionType'] as String,
      isInternetAvailable: devMap['isInternetAvailable'] as bool,
      platform: devMap['platform'] as String,
      deviceName: devMap['deviceName'] as String,
      osVersion: devMap['osVersion'] as String,
      isScreenLocked: devMap['isScreenLocked'] as bool,
      isBatterySaverEnabled: devMap['isBatterySaverEnabled'] as bool,
      isLowPowerMode: devMap['isLowPowerMode'] as bool,
      timeZone: devMap['timeZone'] as String,
      locale: devMap['locale'] as String,
    );

    final medMap = map['medical'] as Map<String, dynamic>;
    final medInfoMap = medMap['medicalInfo'] as Map<String, dynamic>;
    final medicalInfo = MedicalInformation(
      bloodGroup: medInfoMap['bloodGroup'] as String,
      allergies: List<String>.from(medInfoMap['allergies'] as List),
      medicalConditions: List<String>.from(medInfoMap['medicalConditions'] as List),
      currentMedications: List<String>.from(medInfoMap['currentMedications'] as List),
    );
    final emergInfoMap = medMap['emergencyInfo'] as Map<String, dynamic>;
    final emergencyInfo = EmergencyInformation(
      emergencyNotes: emergInfoMap['emergencyNotes'] as String,
      doctorName: emergInfoMap['doctorName'] as String,
      doctorPhone: emergInfoMap['doctorPhone'] as String,
      insuranceProvider: emergInfoMap['insuranceProvider'] as String,
      insurancePolicyNumber: emergInfoMap['insurancePolicyNumber'] as String,
      preferredHospital: emergInfoMap['preferredHospital'] as String,
    );
    final medical = MedicalSection(
      medicalInfo: medicalInfo,
      emergencyInfo: emergencyInfo,
    );

    final respList = map['responders'] as List;
    final responders = ResponderSection(
      responders: respList.map((item) {
        final r = item as Map<String, dynamic>;
        return EmergencyResponder(
          id: r['id'] as String,
          name: r['name'] as String,
          relationship: r['relationship'] as String,
          phone: r['phone'] as String,
          notificationStatus: ResponderNotificationStatus.values.firstWhere(
            (status) => status.name == r['notificationStatus'],
            orElse: () => ResponderNotificationStatus.pending,
          ),
          isAcknowledged: r['isAcknowledged'] as bool,
          acknowledgedTime: r['acknowledgedTime'] != null
              ? DateTime.parse(r['acknowledgedTime'] as String)
              : null,
        );
      }).toList(),
    );

    final eventList = map['timeline'] as List;
    final timeline = TimelineSection(
      events: eventList.map((item) {
        final e = item as Map<String, dynamic>;
        return TimelineEvent(
          id: e['id'] as String,
          title: e['title'] as String,
          timestamp: DateTime.parse(e['timestamp'] as String),
          description: e['description'] as String,
        );
      }).toList(),
    );

    return EmergencyPacket(
      id: map['id'] as String,
      sessionId: map['sessionId'] as String,
      version: map['version'] as int,
      type: map['type'] as String,
      status: map['status'] as String,
      startedAt: DateTime.parse(map['startedAt'] as String),
      currentTime: DateTime.parse(map['currentTime'] as String),
      duration: Duration(milliseconds: map['durationMs'] as int),
      metadata: metadata,
      location: location,
      device: device,
      medical: medical,
      responders: responders,
      timeline: timeline,
    );
  }
}
