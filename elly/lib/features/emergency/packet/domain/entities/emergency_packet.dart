/// emergency_packet.dart
///
/// Master aggregated, versioned, immutable document representing
/// all data collected during an active emergency event.

library;

import 'package:equatable/equatable.dart';
import 'device_section.dart';
import 'location_section.dart';
import 'medical_section.dart';
import 'packet_metadata.dart';
import 'responder_section.dart';
import 'timeline_section.dart';

class EmergencyPacket extends Equatable {
  const EmergencyPacket({
    required this.id,
    required this.sessionId,
    required this.version,
    required this.type,
    required this.status,
    required this.startedAt,
    required this.currentTime,
    required this.duration,
    required this.metadata,
    required this.location,
    required this.device,
    required this.medical,
    required this.responders,
    required this.timeline,
  });

  /// The unique identifier of the emergency event.
  final String id;

  /// The unique active session reference.
  final String sessionId;

  /// Schema version of the Emergency Data Packet.
  final int version;

  /// Trigger mechanism (e.g. "manual", "crash_detection").
  final String type;

  /// Lifecycle status (e.g. "active", "completed").
  final String status;

  /// Time when the emergency session started.
  final DateTime startedAt;

  /// Timestamp of when this packet was compiled.
  final DateTime currentTime;

  /// Total elapsed duration since the trigger.
  final Duration duration;

  /// Packet metadata (size, checksum, updated fields).
  final PacketMetadata metadata;

  /// Hardware location section.
  final LocationSection location;

  /// Hardware device telemetry section.
  final DeviceSection device;

  /// Local medical and emergency profile section.
  final MedicalSection medical;

  /// Responder notification states section.
  final ResponderSection responders;

  /// Live timeline log section.
  final TimelineSection timeline;

  EmergencyPacket copyWith({
    String? id,
    String? sessionId,
    int? version,
    String? type,
    String? status,
    DateTime? startedAt,
    DateTime? currentTime,
    Duration? duration,
    PacketMetadata? metadata,
    LocationSection? location,
    DeviceSection? device,
    MedicalSection? medical,
    ResponderSection? responders,
    TimelineSection? timeline,
  }) {
    return EmergencyPacket(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      version: version ?? this.version,
      type: type ?? this.type,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      currentTime: currentTime ?? this.currentTime,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
      location: location ?? this.location,
      device: device ?? this.device,
      medical: medical ?? this.medical,
      responders: responders ?? this.responders,
      timeline: timeline ?? this.timeline,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        version,
        type,
        status,
        startedAt,
        currentTime,
        duration,
        metadata,
        location,
        device,
        medical,
        responders,
        timeline,
      ];
}
