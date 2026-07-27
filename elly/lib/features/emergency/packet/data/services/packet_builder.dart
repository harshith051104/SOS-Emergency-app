/// packet_builder.dart
///
/// EmergencyPacketBuilder — coordinates the pipeline of contributors
/// to build the aggregate versioned EmergencyPacket. Calculates checksum and size.

library;

import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:elly/features/emergency/packet/domain/entities/emergency_packet.dart';
import 'package:elly/features/emergency/packet/domain/entities/packet_metadata.dart';
import 'package:elly/features/emergency/packet/domain/entities/device_section.dart';
import 'package:elly/features/emergency/packet/domain/entities/location_section.dart';
import 'package:elly/features/emergency/packet/domain/entities/medical_section.dart';
import 'package:elly/features/emergency/packet/domain/entities/responder_section.dart';
import 'package:elly/features/emergency/packet/domain/entities/timeline_section.dart';
import 'packet_contributor.dart';

class EmergencyPacketBuilder {
  EmergencyPacketBuilder(this._contributors) : _uuid = const Uuid();

  final List<PacketContributor> _contributors;
  final Uuid _uuid;

  Uuid get uuid => _uuid;


  /// Executes all contributors sequentially to compile the full EmergencyPacket.
  Future<EmergencyPacket> build({
    required String id,
    required String sessionId,
    required String type,
  }) async {
    final context = EmergencyPacketBuilderContext(
      id: id,
      sessionId: sessionId,
      type: type,
      startedAt: DateTime.now(),
    );

    // Run the contributor pipeline
    for (final contributor in _contributors) {
      await contributor.contribute(context);
    }

    // Double check that all sections were populated (or use fallbacks)
    final location = context.location ??
        LocationSectionFallback.create();
    final device = context.device ??
        DeviceSectionFallback.create();
    final medical = context.medical ??
        MedicalSectionFallback.create();
    final responders = context.responders ??
        ResponderSectionFallback.create();
    final timeline = context.timeline ??
        TimelineSectionFallback.create();

    // Serialize to estimate size and generate integrity checksum
    final serializedData = _serializeForTelemetry(
      id: id,
      sessionId: sessionId,
      type: type,
      location: location,
      device: device,
      medical: medical,
      responders: responders,
      timeline: timeline,
    );

    final byteLength = utf8.encode(serializedData).length;
    final packetSize = '${(byteLength / 1024.0).toStringAsFixed(2)} KB';
    final checksum = _calculateFnv1aChecksum(serializedData);

    final metadata = PacketMetadata(
      created: context.startedAt,
      updated: DateTime.now(),
      version: 1, // Document schema version
      generatedBy: 'ELLY_SOS_V1',
      packetSize: packetSize,
      checksum: checksum,
    );

    return EmergencyPacket(
      id: id,
      sessionId: sessionId,
      version: 1,
      type: type,
      status: 'active',
      startedAt: context.startedAt,
      currentTime: DateTime.now(),
      duration: DateTime.now().difference(context.startedAt),
      metadata: metadata,
      location: location,
      device: device,
      medical: medical,
      responders: responders,
      timeline: timeline,
    );
  }

  /// Estimates size by converting variables to a quick telemetry string.
  String _serializeForTelemetry({
    required String id,
    required String sessionId,
    required String type,
    required dynamic location,
    required dynamic device,
    required dynamic medical,
    required dynamic responders,
    required dynamic timeline,
  }) {
    return '$id|$sessionId|$type|${location.latitude},${location.longitude}|${device.batteryPercent}|${medical.medicalInfo.bloodGroup}|${responders.responders.length}|${timeline.events.length}';
  }

  /// Implements 32-bit FNV-1a high-performance checksum hash compatible with Web, Mobile, and Desktop.
  String _calculateFnv1aChecksum(String input) {
    var hash = 0x811c9dc5;
    final bytes = utf8.encode(input);
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0').toUpperCase();
  }
}

// Fallback helpers to keep the system robust and prevent null pointer crashes

class LocationSectionFallback {
  static LocationSection create() {
    return LocationSection(
      latitude: null,
      longitude: null,
      address: 'Location Unavailable',
      accuracy: 'Unknown',
      timestamp: DateTime.now(),
      permissionStatus: 'denied',
      isGpsEnabled: false,
      isMockLocation: false,
    );
  }
}

class DeviceSectionFallback {
  static DeviceSection create() {
    return const DeviceSection(
      batteryPercent: 0,
      isCharging: false,
      connectionType: 'none',
      isInternetAvailable: false,
      platform: 'Unknown',
      deviceName: 'Generic Device',
      osVersion: 'Unknown Version',
      isScreenLocked: false,
      isBatterySaverEnabled: false,
      isLowPowerMode: false,
      timeZone: 'UTC',
      locale: 'en',
    );
  }
}

class MedicalSectionFallback {
  static MedicalSection create() {
    return const MedicalSection(
      medicalInfo: MedicalInformation(
        bloodGroup: 'Unknown',
        allergies: [],
        medicalConditions: [],
        currentMedications: [],
      ),
      emergencyInfo: EmergencyInformation(
        emergencyNotes: 'No notes logged.',
        doctorName: 'Unknown Doctor',
        doctorPhone: 'N/A',
        insuranceProvider: 'None',
        insurancePolicyNumber: 'N/A',
        preferredHospital: 'Any Nearest Hospital',
      ),
    );
  }
}

class ResponderSectionFallback {
  static ResponderSection create() {
    return const ResponderSection(responders: []);
  }
}

class TimelineSectionFallback {
  static TimelineSection create() {
    return const TimelineSection(events: []);
  }
}
