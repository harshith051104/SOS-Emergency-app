/// packet_contributor.dart
///
/// Defines the builder context container and the contributor interface
/// contract used to construct a versioned Emergency Data Packet.

library;

import '../../domain/entities/device_section.dart';
import '../../domain/entities/location_section.dart';
import '../../domain/entities/medical_section.dart';
import '../../domain/entities/responder_section.dart';
import '../../domain/entities/timeline_section.dart';

class EmergencyPacketBuilderContext {
  EmergencyPacketBuilderContext({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.startedAt,
  });

  final String id;
  final String sessionId;
  final String type;
  final DateTime startedAt;

  // Section fields to be populated by the contributor pipeline
  LocationSection? location;
  DeviceSection? device;
  MedicalSection? medical;
  ResponderSection? responders;
  TimelineSection? timeline;
}

abstract interface class PacketContributor {
  /// Appends or updates data inside the builder context.
  Future<void> contribute(EmergencyPacketBuilderContext context);
}
